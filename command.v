module redict

// import time

pub interface Cmder {
	name() string
	full_name() string
	args() []Value
	string_arg(int) string
	first_key_pos() int
	// read_timeout() time.Duration
	error() !
mut:
	read_reply(mut rd ProtoReader) !
	set_first_key_pos(int)
	set_error(err IError)
}

fn write_cmds(mut wr ProtoWriter, cmds []Cmder) ! {
	for cmd in cmds {
		write_cmd(mut wr, cmd)!
	}
}

fn write_cmd(mut wr ProtoWriter, cmd Cmder) ! {
	wr.write_args(cmd.args())!
}

struct BaseCmd {
	args []Value
mut:
	error   ?IError
	key_pos int
}

pub fn (cmd &BaseCmd) name() string {
	if cmd.args.len == 0 {
		return ''
	}
	return cmd.string_arg(0)
}

pub fn (cmd &BaseCmd) full_name() string {
	mut name := cmd.name()
	match name {
		'cluster', 'command' {
			if cmd.args.len == 1 {
				return name
			}
			if cmd.args[1] is string {
				return '${name} ${cmd.args[1]}'
			}
			return name
		}
		else {
			return name
		}
	}
}

pub fn (cmd &BaseCmd) args() []Value {
	return cmd.args
}

fn (cmd &BaseCmd) string_arg(pos int) string {
	if pos < 0 || pos >= cmd.args.len {
		return ''
	}
	arg := cmd.args[pos]
	match arg {
		string {
			return arg
		}
		else {
			return '${arg}'
		}
	}
}

fn (cmd &BaseCmd) first_key_pos() int {
	return cmd.key_pos
}

fn (mut cmd BaseCmd) set_first_key_pos(key_pos int) {
	cmd.key_pos = key_pos
}

fn (mut cmd BaseCmd) set_error(err IError) {
	cmd.error = err
}

pub fn (cmd &BaseCmd) error() ! {
	if error := cmd.error {
		return error
	}
}

struct Cmd {
	BaseCmd
mut:
	val Value
}

pub struct IntCmd {
	BaseCmd
mut:
	val i64
}

fn new_int_cmd(args ...Value) &IntCmd {
	return &IntCmd{
		BaseCmd: BaseCmd{
			args: args
		}
	}
}

pub fn (cmd &IntCmd) value() i64 {
	return cmd.val
}

pub fn (cmd &IntCmd) result() !i64 {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd IntCmd) read_reply(mut rd ProtoReader) ! {
	v := rd.read_int()!
	cmd.val = v
}

pub struct StatusCmd {
	BaseCmd
mut:
	val string
}

fn new_status_cmd(args ...Value) &StatusCmd {
	return &StatusCmd{
		args: args
	}
}

pub fn (mut cmd StatusCmd) set_value(value string) {
	cmd.val = value
}

pub fn (cmd &StatusCmd) value() string {
	return cmd.val
}

pub fn (cmd &StatusCmd) result() !string {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd StatusCmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = rd.read_string()!
}

pub struct BoolCmd {
	BaseCmd
mut:
	val bool
}

fn new_bool_cmd(args ...Value) &BoolCmd {
	return &BoolCmd{
		BaseCmd: BaseCmd{
			args: args
		}
	}
}

pub fn (cmd &BoolCmd) value() bool {
	return cmd.val
}

pub fn (cmd &BoolCmd) result() !bool {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd BoolCmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = rd.read_bool() or {
		// `SET key value NX` returns nil when key already exists.
		// `SETNX key value` returns bool (0/1). So convert nil to bool.
		cmd.val = false // value is set false, and Nil is returned.
		return err
	}
}

pub struct StringCmd {
	BaseCmd
mut:
	val string
}

fn new_string_cmd(args ...Value) &StringCmd {
	return &StringCmd{
		args: args
	}
}

pub fn (cmd &StringCmd) value() string {
	return cmd.val
}

pub fn (cmd &StringCmd) result() !string {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd StringCmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = rd.read_string()!
}

pub struct FloatCmd {
	BaseCmd
mut:
	val f64
}

fn new_float_cmd(args ...Value) &FloatCmd {
	return &FloatCmd{
		args: args
	}
}

pub fn (cmd &FloatCmd) value() f64 {
	return cmd.val
}

pub fn (cmd &FloatCmd) result() !f64 {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd FloatCmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = rd.parse_float()!
}

pub struct MapStringValueCmd {
	BaseCmd
mut:
	val map[string]Value
}

fn new_map_string_value_cmd(args ...Value) &MapStringValueCmd {
	return &MapStringValueCmd{
		args: args
	}
}

pub fn (cmd &MapStringValueCmd) val() Value {
	return cmd.val
}

fn (mut cmd MapStringValueCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_map_len()!
	cmd.val = map[string]Value{}
	for i := 0; i < n; i += 1 {
		k := rd.read_string()!
		v := rd.read_reply() or {
			if is_nil(err) {
				cmd.val[k] = redict_nil
				continue
			}

			if is_error(err) {
				cmd.val[k] = err
				continue
			}

			return err
		}

		cmd.val[k] = v
	}
}

pub struct StringSliceCmd {
	BaseCmd
mut:
	val []string
}

fn new_string_slice_cmd(args ...Value) &StringSliceCmd {
	return &StringSliceCmd{
		args: args
	}
}

pub fn (cmd &StringSliceCmd) value() []string {
	return cmd.val
}

pub fn (cmd &StringSliceCmd) result() ![]string {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd StringSliceCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	cmd.val = []string{len: n}
	for i := 0; i < n; i++ {
		s := rd.read_string() or {
			if is_nil(err) {
				continue
			}
			return err
		}
		cmd.val[i] = s
	}
}
