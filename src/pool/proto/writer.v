module proto

import io
import strconv
import time
import x.json2 as json

pub struct Writer {
mut:
	writer  io.Writer
	buf_len []u8
	buf_num []u8
}

pub fn new_writer(io_writer io.Writer) Writer {
	return Writer{
		writer: io_writer
		buf_len: []u8{len: 64, cap: 64}
		buf_num: []u8{len: 64, cap: 64}
	}
}

pub fn (mut wr Writer) write_args(args []json.Any) ! {
	wr.writer.write(resp_array.bytes())!
	wr.write_len(args.len)!
	for arg in args {
		wr.write_arg(arg)!
	}
}

fn (mut wr Writer) write_arg(v json.Any) ! {
	match v {
		string {
			wr.write_bytes(v.bytes())!
		}
		i8, i16, int, i64 {
			wr.write_signed(i64(v))!
		}
		u8, u16, u32, u64 {
			wr.write_unsigned(u64(v))!
		}
		f32, f64 {
			wr.write_float(f64(v))!
		}
		bool {
			if v {
				wr.write_unsigned(1)!
			}
			wr.write_unsigned(0)!
		}
		time.Time {
			wr.write_time(v)!
		}
		else {
			// If v is []json.Any or map[string]json.Any
			// https://github.com/vlang/v/blob/master/vlib/x/json2/types.v
			return error('Cannot marshal ${v}')
		}
	}
}

fn (mut wr Writer) write_len(n int) ! {
	wr.buf_len = []u8{} // TODO reset consistently with reader
	wr.buf_len << strconv.format_int(n, 10).bytes()
	wr.buf_len << resp_crlf.bytes()
	wr.writer.write(wr.buf_len)!
}

fn (mut wr Writer) write_bytes(b []byte) ! {
	wr.writer.write(resp_string.bytes())!

	wr.write_len(b.len)!

	wr.writer.write(b)!

	wr.writer.write(resp_crlf.bytes())!
}

fn (mut wr Writer) write_signed(n i64) ! {
	wr.buf_num = []u8{}
	wr.buf_num << strconv.format_int(n, 10).bytes()
	wr.write_bytes(wr.buf_num)!
}

fn (mut wr Writer) write_unsigned(n u64) ! {
	wr.buf_num = []u8{}
	wr.buf_num << strconv.format_uint(n, 10).bytes()
	wr.write_bytes(wr.buf_num)!
}

fn (mut wr Writer) write_float(n f64) ! {
	wr.buf_num = []u8{}
	wr.buf_num << strconv.format_fl(n, strconv.BF_param{}).bytes()
	wr.write_bytes(wr.buf_num)!
}

fn (mut wr Writer) write_time(v time.Time) ! {
	wr.buf_num = []u8{}
	wr.buf_num << v.format_rfc3339().bytes()
	wr.write_bytes(wr.buf_num)!
}
