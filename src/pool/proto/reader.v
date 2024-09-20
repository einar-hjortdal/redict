module proto

import io
import math
// import math.big
import strconv
import x.json2 as json

pub struct Reader {
	// mfails is the maximum number of fails after which it is assumed that the stream has ended.
	mfails int
mut:
	reader io.Reader
	// buf is the buffer read with `Reader.read`.
	buf []u8
	// line is the line constructed by scanning buf with private_read_line.
	line []u8
	// Current offset in `buf`.
	offset int
	// fails is the number of times private_read_line read 0 bytes in a row.
	fails int
}

pub fn new_reader(io_reader io.Reader) Reader {
	return Reader{
		reader: io_reader
		buf: []u8{len: 4096, cap: 4096}
		mfails: 2
	}
}

pub fn (mut rd Reader) reset() {
	rd.buf = []u8{len: 4096, cap: 4096}
	rd.line = []u8{}
	rd.offset = 0
	rd.fails = 0
}

fn (mut rd Reader) private_read_line() !string {
	// Fill buffer
	if rd.offset == 0 {
		bytes_read := rd.reader.read(mut rd.buf)! // TODO hangs if invoked on empty reply, why?
		if bytes_read == 0 {
			if rd.fails < rd.mfails {
				rd.fails += 1
				return rd.private_read_line()
			}
		}
	}

	// Build string from buffer
	for i := rd.offset; i < rd.buf.len; i += 1 {
		rd.line << rd.buf[i]
		// Stop at the first `\n` encountered. A buffered response may contain more than one `\n`.
		if rd.buf[i] == `\n` {
			res := rd.line.bytestr()
			rd.line = []u8{}
			rd.offset += 1
			return res
		}
		rd.offset += 1
	}

	return error(r'Invalid server response: response does not end with \n')
}

pub fn (mut rd Reader) read_line() !string {
	line := rd.read()!

	if line.starts_with(resp_error) {
		return error(line.trim_string_right(resp_error))
	}
	if line.starts_with(resp_nil) {
		return error('nil')
	}
	if line.starts_with(resp_blob_error) {
		return rd.read_string_reply(line)!
	}
	// Discard attribute type
	if line.starts_with(resp_attr) {
		rd.discard(line)!
		return rd.read_line()!
	}
	return line
}

fn (mut rd Reader) read() !string {
	b := rd.private_read_line()!
	if b == resp_crlf || !b.ends_with(resp_crlf) {
		return error('Invalid reply: ${b}')
	}
	return b.trim_string_right(resp_crlf)
}

fn (mut rd Reader) read_string_reply(line string) !string {
	n := reply_len(line)!
	// read exactly n+2 bytes from rd.buf into b
	mut b := []u8{len: n + 2, cap: n + 2}
	i_end := rd.offset + n + 2
	for i, j := rd.offset, 0; i < i_end; i, j = i + 1, j + 1 {
		b[j] = rd.buf[i]
		rd.offset += 1
	}
	return b.bytestr().trim_string_right(resp_crlf)
}

fn reply_len(line string) !int {
	n := strconv.atoi(line[1..])!

	if n < -1 {
		return error('Invalid reply: ${line}')
	}

	if line.starts_with(resp_string) || line.starts_with(resp_verbatim)
		|| line.starts_with(resp_blob_error) || line.starts_with(resp_array)
		|| line.starts_with(resp_set) || line.starts_with(resp_push) || line.starts_with(resp_map)
		|| line.starts_with(resp_attr) {
		if n == -1 {
			return error('nil') // TODO is this RESP2?
		}
	}
	return n
}

pub fn (mut rd Reader) discard(line string) ! {
	if line.len == 0 {
		return error('Invalid line')
	}

	if line.starts_with(resp_status) || line.starts_with(resp_error) || line.starts_with(resp_int)
		|| line.starts_with(resp_nil) || line.starts_with(resp_float) || line.starts_with(resp_bool)
		|| line.starts_with(resp_big_int) {
		return
	}

	n := reply_len(line)!

	if line.starts_with(resp_blob_error) || line.starts_with(resp_string)
		|| line.starts_with(resp_verbatim) {
		// Skip over the next n+2 bytes
		mut discarded := []u8{cap: n + 2}
		_ := rd.reader.read(mut discarded)!
	}
	if line.starts_with(resp_array) || line.starts_with(resp_set) || line.starts_with(resp_push) {
		for i := 0; i < n; i++ {
			rd.discard_next()!
		}
	}
	if line.starts_with(resp_map) || line.starts_with(resp_attr) {
		for i := 0; i < n * 2; i++ {
			rd.discard_next()!
		}
	}

	return error("Can't parse ${line}")
}

pub fn (mut rd Reader) discard_next() ! {
	line := rd.read()!
	return rd.discard(line)
}

// read_reply parses the data returned by read_line()
pub fn (mut rd Reader) read_reply() !json.Any {
	line := rd.read_line()!
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
	// big int is not part of json.Any, consider returning a string instead or create a sum type.
	// if line.starts_with(resp_big_int) {
	// 	return rd.read_big_int(line)!
	// }
	if line.starts_with(resp_string) {
		return rd.read_string_reply(line)!
	}
	if line.starts_with(resp_verbatim) {
		return rd.read_verb(line)!
	}
	if line.starts_with(resp_array) || line.starts_with(resp_set) || line.starts_with(resp_push) {
		return rd.read_slice(line)!
	}
	if line.starts_with(resp_map) {
		return rd.read_map(line)!
	}
	return error("Can't parse ${line}")
}

fn (rd Reader) read_float(line string) !f64 {
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

fn (rd Reader) private_read_bool(line string) !bool {
	if line[1..] == 't' {
		return true
	}
	if line[1..] == 'f' {
		return false
	}
	return error("Can't parse bool reply: ${line}")
}

// fn (rd Reader) read_big_int(line string) !big.Integer {
// 	if i := big.integer_from_string(line[1..]) {
// 		return i
// 	} else {
// 		return error("Can't parse bigInt reply: ${line}")
// 	}
// }

fn (mut rd Reader) read_verb(line string) !string {
	s := rd.read_string_reply(line)!
	if s.len < 4 || s[3] != ':'[0] {
		return error("Can't parse verbatim string reply: ${line}")
	}
	return s[4..]
}

fn (mut rd Reader) read_slice(line string) ![]json.Any {
	// TODO n := reply_len(line)!

	mut val := []json.Any{} // TODO len: n
	for i := 0; i < val.len; i++ {
		if v := rd.read_reply() {
			val[i] = v
		} else {
			val[i] = err.msg()
		}
	}
	return val
}

fn (mut rd Reader) read_map(line string) !map[string]json.Any {
	n := reply_len(line)!
	mut m := map[string]json.Any{}
	for i := 0; i < n; i++ {
		k := rd.read_reply()! // expected string
		match k {
			string {
				if v := rd.read_reply() {
					m[k] = v
				} else {
					m[k] = err.msg()
				}
				return m
			}
			else {
				return error('Map expected string key but got ${typeof(k).name} instead')
			}
		}
	}
}

/*
*
*
* Methods used by Cmdable
*
*
*/

pub fn (mut rd Reader) read_string() !string {
	line := rd.read_line()!

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
		return rd.read_verb(line)
	}
	// if line.starts_with(resp_big_int) {
	// 	b := rd.read_big_int(line)!
	// 	return '${b}'
	// }
	return error("Can't parse reply ${line} reading string")
}

pub fn (mut rd Reader) read_bool() !bool {
	s := rd.read_string() or { return false }
	return s == 'OK' || s == '1' || s == 'true'
}

pub fn (mut rd Reader) read_int() !i64 {
	line := rd.read_line()!

	if line.starts_with(resp_status) {
		return strconv.parse_int(line.trim_string_left(resp_status), 10, 64)
	}
	if line.starts_with(resp_int) {
		return strconv.parse_int(line.trim_string_left(resp_int), 10, 64)
	}
	if line.starts_with(resp_string) {
		i := rd.read_string_reply(line)!
		return strconv.parse_int(i, 10, 64)
	}
	// if line.starts_with(resp_big_int) {
	// 	b := rd.read_big_int(line)!
	// 	return '${b}'
	// }
	// 	if b !is i64 {
	// 		error("big_int ${b} value out of range")
	// 	}
	// 	return b.Int64(), nil
	// }
	return error("Can't parse int reply: ${line}")
}

// read_map_len reads the length of the map type.
// If responding to the array type (RespArray/RespSet/RespPush), it must be a multiple of 2 and return
// n/2. Other types will return an error.
pub fn (mut rd Reader) read_map_len() !int {
	line := rd.read_line()!

	if line.starts_with(resp_map) {
		return reply_len(line)
	}
	if line.starts_with(resp_array) || line.starts_with(resp_set) || line.starts_with(resp_push) {
		// Some commands may respond to array types.
		n := reply_len(line)!
		if n % 2 != 0 {
			return error('The length of the array must be a multiple of 2, got: ${n}')
		}
		return n / 2
	}
	return error("Can't parse map reply: ${line}")
}
