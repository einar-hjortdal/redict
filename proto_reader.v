module redict

import io
import math
// import math.big
import strconv

const buf_len = 4096

struct ProtoReader {
mut:
	reader &io.BufferedReader
}

fn new_reader(mut io_reader io.Reader) &ProtoReader {
	return &ProtoReader{
		reader: io.new_buffered_reader(reader: io_reader)
	}
}

fn (mut rd ProtoReader) read_line() !string {
	l := rd.read()!

	match l[0].ascii_str() {
		resp_error {
			return new_redict_error(l.trim_string_right(resp_error))
		}
		resp_nil {
			return redict_nil
		}
		resp_blob_error {
			blob_error := rd.read_string_reply(l)!
			return new_redict_error(blob_error)
		}
		resp_attr {
			rd.discard(l)!
			return rd.read_line()
		}
		else {} // TODO default
	}

	return l
}

fn (mut rd ProtoReader) read() !string {
	return rd.reader.read_line() // note: read_line trims the final `\n` and `\r\n`
}

fn (mut rd ProtoReader) read_string_reply(line string) !string {
	n := reply_len(line)!
	// read exactly n+2 bytes from rd.buf into b
	mut b := []u8{len: n + 2}
	rd.reader.read(mut b)!
	return b.bytestr().trim_string_right(resp_crlf)
}

fn reply_len(line string) !int {
	n := strconv.atoi(line[1..])!

	if n < -1 {
		return new_redict_error('Invalid reply: ${line}')
	}

	if line.starts_with(resp_string) || line.starts_with(resp_verbatim)
		|| line.starts_with(resp_blob_error) || line.starts_with(resp_array)
		|| line.starts_with(resp_set) || line.starts_with(resp_push) || line.starts_with(resp_map)
		|| line.starts_with(resp_attr) {
		if n == -1 {
			return redict_nil // TODO is this RESP2?
		}
	}
	return n
}

fn (mut rd ProtoReader) discard(line string) ! {
	if line.len == 0 {
		return new_redict_error('Invalid line')
	}

	match line[0].ascii_str() {
		resp_status, resp_error, resp_int, resp_nil, resp_float, resp_bool, resp_big_int {
			return
		}
		else {}
	}

	n := reply_len(line)!
	match line[0].ascii_str() {
		resp_blob_error, resp_string, resp_verbatim {
			// Skip over the next n+2 bytes
			mut discarded := []u8{cap: n + 2}
			_ := rd.reader.read(mut discarded)!
		}
		resp_array, resp_set, resp_push {
			for i := 0; i < n; i++ {
				rd.discard_next()!
			}
		}
		resp_map, resp_attr {
			for i := 0; i < n * 2; i++ {
				rd.discard_next()!
			}
		}
		else {}
	}

	return error("Can't parse ${line}")
}

fn (mut rd ProtoReader) discard_next() ! {
	line := rd.read()!
	return rd.discard(line)
}

// read_reply parses the data returned by read_line()
fn (mut rd ProtoReader) read_reply() !Value {
	line := rd.read_line()!
	match line[0].ascii_str() {
		resp_status {
			return line.trim_string_left(resp_status)
		}
		resp_int {
			return strconv.parse_int(line.trim_string_left(resp_int), 10, 64)!
		}
		resp_float {
			return rd.read_float(line)!
		}
		resp_bool {
			return rd.private_read_bool(line)!
		}
		// resp_big_int {
		// 	return rd.read_big_int(line)!
		// }
		resp_string {
			return rd.read_string_reply(line)!
		}
		resp_verbatim {
			return rd.read_verb(line)!
		}
		resp_array, resp_set, resp_push {
			return rd.read_slice(line)!
		}
		resp_map {
			return rd.read_map(line)!
		}
		else {
			return new_redict_error("ProtoReader.read_reply: Can't parse ${line}")
		}
	}
}

fn (mut rd ProtoReader) parse_float() !f64 {
	line := rd.read_line()!
	match line[0].ascii_str() {
		resp_float {
			return rd.read_float(line)
		}
		resp_status {
			return line[1..].f64() // TODO error if can't convert
		}
		resp_string {
			s := rd.read_string_reply(line)!
			return s.f64() // TODO error if can't convert
		}
		else {
			return new_redict_error("ProtoReader.read_reply: Can't parse float reply ${line}")
		}
	}
}

fn (rd ProtoReader) read_float(line string) !f64 {
	if line[1..] == 'inf' {
		return math.inf(1)
	}
	if line[1..] == '-inf' {
		return math.inf(-1)
	}
	if line[1..] == 'nan' || line[1..] == '-nan' {
		return math.nan()
	}
	return strconv.atof64(line[1..])!
}

fn (rd ProtoReader) private_read_bool(line string) !bool {
	if line[1..] == 't' {
		return true
	}
	if line[1..] == 'f' {
		return false
	}
	return new_redict_error("Can't parse bool reply: ${line}")
}

// fn (rd ProtoReader) read_big_int(line string) !big.Integer {
// 	if i := big.integer_from_string(line[1..]) {
// 		return i
// 	} else {
// 		return error("Can't parse bigInt reply: ${line}")
// 	}
// }

fn (mut rd ProtoReader) read_verb(line string) !string {
	s := rd.read_string_reply(line)!
	if s.len < 4 || (s.len >= 4 && s[3] != `:`) {
		return new_redict_error("Can't parse verbatim string reply: ${line}")
	}
	return s[4..]
}

fn (mut rd ProtoReader) read_slice(line string) ![]?Value {
	n := reply_len(line)!
	mut val := []?Value{len: n, init: none}
	for i := 0; i < n; i++ {
		v := rd.read_reply() or {
			match err {
				RedictError {
					if is_nil(err) {
						val[i] = none
						continue
					}

					val[i] = err
					continue
				}
				else {
					return err
				}
			}
		}
		val[i] = v
	}
	return val
}

fn (mut rd ProtoReader) read_map(line string) !map[string]?Value {
	n := reply_len(line)!
	mut m := map[string]?Value{}
	for i := 0; i < n; i++ {
		k := rd.read_reply()!
		match k {
			string {
				v := rd.read_reply() or {
					match err {
						RedictError {
							if is_nil(err) {
								m[k] = none
								continue
							}

							m[k] = err
							continue
						}
						else {
							return err
						}
					}
				}
				m[k] = v
			}
			else {
				return new_redict_error('ProtoReader.read_map: ProtoReader.read_reply returned unexpect type')
			}
		}
	}
	return m
}

fn (mut rd ProtoReader) read_string() !string {
	l := rd.read_line()!

	match l[0].ascii_str() {
		resp_status, resp_int, resp_float {
			return l[1..]
		}
		resp_string {
			return rd.read_string_reply(l)
		}
		resp_bool {
			b := rd.private_read_bool(l)!
			return '${b}'
		}
		resp_verbatim {
			return rd.read_verb(l)!
		}
		// resp_big_int {
		// 	b := rd.read_big_int(line)!
		// 	return '${b}'
		// }
		else {
			return new_redict_error("ProtoReader.read_string: Can't parse reply ${l} reading string")
		}
	}
}

fn (mut rd ProtoReader) read_bool() !bool {
	s := rd.read_string()!
	return s == 'OK' || s == '1' || s == 'true'
}

fn (mut rd ProtoReader) read_int() !i64 {
	line := rd.read_line()!

	match line[0].ascii_str() {
		resp_int, resp_status {
			return strconv.parse_int(line[1..], 10, 64)!
		}
		resp_string {
			i := rd.read_string_reply(line)!
			return strconv.parse_int(i, 10, 64)!
		}
		// resp_big_int {
		// 	b := rd.read_big_int(line)!
		// 	return '${b}'
		// }
		// 	if b !is i64 {
		// 		error("big_int ${b} value out of range")
		// 	}
		// 	return b.Int64() or ProtoNil
		// }
		else {
			return new_redict_error("Can't parse int reply: ${line}")
		}
	}
}

fn (mut rd ProtoReader) read_array_len() !int {
	line := rd.read_line()!
	match line[0].ascii_str() {
		resp_array, resp_set, resp_push {
			return reply_len(line)
		}
		else {
			return new_redict_error("can't parse array/set/push reply: ${line}")
		}
	}
}

fn (mut rd ProtoReader) read_map_len() !int {
	line := rd.read_line()!
	match line[0].ascii_str() {
		resp_map {
			return reply_len(line)!
		}
		resp_array, resp_set, resp_push {
			// Some commands may respond to array types.
			n := reply_len(line)!
			if n % 2 != 0 {
				return new_redict_error('The length of the array must be a multiple of 2, got: ${n}')
			}
			return n / 2
		}
		else {
			return new_redict_error("Can't parse map reply: ${line}")
		}
	}
}
