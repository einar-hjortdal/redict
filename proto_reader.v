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

// Should return string or Nil or RedictError.
fn (mut rd ProtoReader) read_line() !Value {
	l := rd.read()!

	if l.starts_with(resp_error) {
		return RedictError{
			msg: l.trim_string_right(resp_error)
		}
	}

	if l.starts_with(resp_nil) {
		return Nil{}
	}

	if l.starts_with(resp_blob_error) {
		return rd.read_string_reply(l)!
	}

	// Discard attribute type
	if l.starts_with(resp_attr) {
		rd.discard(l)!
		return rd.read_line()!
	}

	return l
}

fn (mut rd ProtoReader) read() !string {
	return rd.reader.read_line() // note: read_line trims the final `\n` (seems like it trims \r\n)
}

// Should return string or Nil or RedictError.
fn (mut rd ProtoReader) read_string_reply(line string) !Value {
	n := reply_len(line)!
	match n {
		int {
			// read exactly n+2 bytes from rd.buf into b
			n_plus_2 := n + 2
			mut b := []u8{len: n_plus_2}
			rd.reader.read(mut b)!
			return b.bytestr().trim_string_right(resp_crlf)
		}
		Nil {
			return n
		}
		else {
			return error(format_error_message('ProtoReader.read_string_reply: reply_len returned unexpect type'))
		}
	}
}

fn reply_len(line string) !Value {
	n := strconv.atoi(line[1..])!

	if n < -1 {
		return error(format_error_message('Invalid reply: ${line}'))
	}

	if line.starts_with(resp_string) || line.starts_with(resp_verbatim)
		|| line.starts_with(resp_blob_error) || line.starts_with(resp_array)
		|| line.starts_with(resp_set) || line.starts_with(resp_push) || line.starts_with(resp_map)
		|| line.starts_with(resp_attr) {
		if n == -1 {
			return Nil{} // TODO is this RESP2?
		}
	}
	return n
}

fn (mut rd ProtoReader) discard(line string) ! {
	if line.len == 0 {
		return error(format_error_message('Invalid line'))
	}

	if line.starts_with(resp_status) || line.starts_with(resp_error) || line.starts_with(resp_int)
		|| line.starts_with(resp_nil) || line.starts_with(resp_float) || line.starts_with(resp_bool)
		|| line.starts_with(resp_big_int) {
		return
	}

	n := reply_len(line)!
	match n {
		int {
			n_plus_2 := n + 2
			n_by_2 := n * 2
			if line.starts_with(resp_blob_error) || line.starts_with(resp_string)
				|| line.starts_with(resp_verbatim) {
				// Skip over the next n+2 bytes
				mut discarded := []u8{cap: n_plus_2}
				_ := rd.reader.read(mut discarded)!
			}
			if line.starts_with(resp_array) || line.starts_with(resp_set)
				|| line.starts_with(resp_push) {
				for i := 0; i < n; i++ {
					rd.discard_next()!
				}
			}
			if line.starts_with(resp_map) || line.starts_with(resp_attr) {
				for i := 0; i < n_by_2; i++ {
					rd.discard_next()!
				}
			}
		}
		Nil {
			return
		}
		else {
			return error(format_error_message('ProtoReader.discard: reply_len returned unexpect type'))
		}
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
	match line {
		string {
			if line.starts_with(resp_status) {
				return line.trim_string_left(resp_status)
			}
			if line.starts_with(resp_int) {
				return strconv.parse_int(line.trim_string_left(resp_int), 10, 64)!
			}
			if line.starts_with(resp_float) {
				return rd.read_float(line)!
			}
			if line.starts_with(resp_bool) {
				return rd.private_read_bool(line)!
			}
			// if line.starts_with(resp_big_int) {
			// 	return rd.read_big_int(line)!
			// }
			if line.starts_with(resp_string) {
				return rd.read_string_reply(line)!
			}
			if line.starts_with(resp_verbatim) {
				return rd.read_verb(line)!
			}
			if line.starts_with(resp_array) || line.starts_with(resp_set)
				|| line.starts_with(resp_push) {
				return rd.read_slice(line)!
			}
			if line.starts_with(resp_map) {
				return rd.read_map(line)!
			}
		}
		Nil {
			return line
		}
		else {
			return error(format_error_message('ProtoReader.read_reply: ProtoReader.read_line returned an Unexpected type'))
		}
	}
	return error(format_error_message("ProtoReader.read_reply: Can't parse ${line}"))
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
	return error(format_error_message("Can't parse bool reply: ${line}"))
}

// fn (rd ProtoReader) read_big_int(line string) !big.Integer {
// 	if i := big.integer_from_string(line[1..]) {
// 		return i
// 	} else {
// 		return error("Can't parse bigInt reply: ${line}")
// 	}
// }

// Should return string or Nil or RedictError.
fn (mut rd ProtoReader) read_verb(line string) !Value {
	s := rd.read_string_reply(line)!
	match s {
		string {
			st := s
			if st.len < 4 || (st.len >= 4 && st[3] != `:`) {
				return error(format_error_message("Can't parse verbatim string reply: ${line}"))
			}
			return st[4..]
		}
		Nil {
			return s
		}
		else {
			return error(format_error_message('ProtoReader.read_verb: Reader.read_string_reply returned unexpect type'))
		}
	}
}

fn (mut rd ProtoReader) read_slice(line string) ![]Value {
	// TODO n := reply_len(line)!

	mut val := []Value{} // TODO len: n
	for i := 0; i < val.len; i++ {
		if v := rd.read_reply() {
			val[i] = v
		} else {
			val[i] = RedictError{
				msg: err.msg()
			}
		}
	}
	return val
}

// Should return map[string]Value, Nil or RedictError
fn (mut rd ProtoReader) read_map(line string) !Value {
	n := reply_len(line)!
	match n {
		int {
			mut m := map[string]Value{}
			for i := 0; i < n; i++ {
				k := rd.read_reply()! // expected string
				match k {
					string {
						v := rd.read_reply()! // read_reply does not currently return errors
						m[k] = v
					}
					else {
						return error(format_error_message('ProtoReader.read_map: ProtoReader.read_reply returned unexpect type'))
					}
				}
			}
			return m
		}
		Nil {
			return n
		}
		else {
			return RedictError{
				msg: format_error_message('ProtoReader.read_map: reply_len returned unexpect type')
			}
		}
	}
}

// Should return string or Nil or RedictError
fn (mut rd ProtoReader) read_string() !Value {
	line := rd.read_line() or { return RedictError{
		msg: err.msg()
	} }

	match line {
		string {
			if line.starts_with(resp_status) {
				return line.trim_string_left(resp_status)
			}
			if line.starts_with(resp_int) {
				return line.trim_string_left(resp_int)
			}
			if line.starts_with(resp_float) {
				return line.trim_string_left(resp_float)
			}
			if line.starts_with(resp_string) {
				return rd.read_string_reply(line)!
			}
			if line.starts_with(resp_bool) {
				b := rd.private_read_bool(line)!
				return '${b}'
			}
			if line.starts_with(resp_verbatim) {
				return rd.read_verb(line)!
			}
			// if line.starts_with(resp_big_int) {
			// 	b := rd.read_big_int(line)!
			// 	return '${b}'
			// }
		}
		Nil {
			return line
		}
		else {
			return error(format_error_message('ProtoReader.read_string: ProtoReader.read_line returned an Unexpected type'))
		}
	}

	return error(format_error_message("ProtoReader.read_string: Can't parse reply ${line} reading string"))
}

fn (mut rd ProtoReader) read_bool() !bool {
	s := rd.read_string() or { return false }
	match s {
		string {
			return s == 'OK' || s == '1' || s == 'true'
		}
		else {
			return error(format_error_message('ProtoReader.read_bool: Reader.read_string returned unexpect type'))
		}
	}
}

// Should return int or Nil or RedictError
fn (mut rd ProtoReader) read_int() !Value {
	line := rd.read_line() or { return RedictError{
		msg: err.msg()
	} }

	match line {
		string {
			if line.starts_with(resp_status) {
				return strconv.parse_int(line.trim_string_left(resp_status), 10, 64)!
			}
			if line.starts_with(resp_int) {
				return strconv.parse_int(line.trim_string_left(resp_int), 10, 64)!
			}
			if line.starts_with(resp_string) {
				i := rd.read_string_reply(line)!
				match i {
					string {
						return strconv.parse_int(i, 10, 64)!
					}
					Nil {
						return i
					}
					else {
						return RedictError{
							msg: format_error_message('ProtoReader.read_int: ProtoReader.read_string_reply returned unexpect type')
						}
					}
				}
			}
			// if line.starts_with(resp_big_int) {
			// 	b := rd.read_big_int(line)!
			// 	return '${b}'
			// }
			// 	if b !is i64 {
			// 		error("big_int ${b} value out of range")
			// 	}
			// 	return b.Int64() or ProtoNil
			// }
		}
		Nil {
			return line
		}
		else {}
	}
	return error(format_error_message("Can't parse int reply: ${line}"))
}

// read_map_len reads the length of the map type.
// Should return int or Nil or RedictError.
// If responding to the array type (RespArray/RespSet/RespPush), it must be a multiple of 2 and return
// n/2. Other types will return an error.
fn (mut rd ProtoReader) read_map_len() !Value {
	line := rd.read_line()!

	match line {
		string {
			if line.starts_with(resp_map) {
				return reply_len(line)!
			}
			if line.starts_with(resp_array) || line.starts_with(resp_set)
				|| line.starts_with(resp_push) {
				// Some commands may respond to array types.
				n := reply_len(line)!
				match n {
					int {
						len := n
						if len % 2 != 0 {
							return error(format_error_message('The length of the array must be a multiple of 2, got: ${n}'))
						}
						return len / 2
					}
					Nil {
						return n
					}
					else {
						return RedictError{
							msg: format_error_message('ProtoReader.read_int: ProtoReader.read_string_reply returned unexpect type')
						}
					}
				}
			}
		}
		Nil {
			return line
		}
		else {
			return error(format_error_message('ProtoReader.read_map_len: Reader.read_string returned unexpect type'))
		}
	}
	return error(format_error_message("Can't parse map reply: ${line}"))
}
