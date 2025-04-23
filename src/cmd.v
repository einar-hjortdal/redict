module redict

// import time

pub interface Cmder {
	name() string
	full_name() string
	args() []Value
	arg_string(int) string
	first_key_pos() int
	val() Value
	// read_timeout() time.Duration
mut:
	set_first_key_pos(int)
	read_reply(mut rd ProtoReader) !
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
	key_pos int
}

pub fn (cmd BaseCmd) name() string {
	if cmd.args.len == 0 {
		return ''
	}
	return to_lower(cmd.arg_string(0))
}

pub fn (cmd BaseCmd) full_name() string {
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

pub fn (cmd BaseCmd) args() []Value {
	return cmd.args
}

fn (cmd BaseCmd) arg_string(pos int) string {
	if pos < 0 || pos >= cmd.args.len {
		return ''
	}
	arg := cmd.args[pos]
	match arg {
		string {
			return *arg
		}
		else {
			return '${arg}'
		}
	}
}

fn (cmd BaseCmd) first_key_pos() int {
	return cmd.key_pos
}

fn (mut cmd BaseCmd) set_first_key_pos(key_pos int) {
	cmd.key_pos = key_pos
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

fn (mut cmd IntCmd) set_val(val i64) {
	cmd.val = val
}

fn (cmd IntCmd) val() Value {
	return cmd.val
}

fn (mut cmd IntCmd) read_reply(mut rd ProtoReader) ! {
	v := rd.read_int()!
	match v {
		i64 {
			cmd.val = v
		}
		else {
			return RedictError{
				msg: format_error_message('IntCmd.read_reply: ProtoReader.read_int returned unexpected type')
			}
		}
	}
}

pub struct StatusCmd {
	BaseCmd
mut:
	val Value
}

fn new_status_cmd(args ...Value) &StatusCmd {
	return &StatusCmd{
		args: args
		val:  Nil{}
	}
}

fn (mut cmd StatusCmd) set_val(val string) {
	cmd.val = val
}

fn (cmd StatusCmd) val() Value {
	return cmd.val
}

fn (mut cmd StatusCmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = rd.read_string()!
}

struct BoolCmd {
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

fn (mut cmd BoolCmd) set_val(val bool) {
	cmd.val = val
}

fn (cmd BoolCmd) val() Value {
	return cmd.val
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
	val Value
}

fn new_string_cmd(args ...Value) &StringCmd {
	return &StringCmd{
		args: args
		val:  Nil{}
	}
}

fn (mut cmd StringCmd) set_val(val string) {
	cmd.val = val
}

fn (cmd StringCmd) val() Value {
	return cmd.val
}

fn (mut cmd StringCmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = rd.read_string()!
}

struct MapStringValueCmd {
	BaseCmd
mut:
	val map[string]Value
}

fn new_map_string_value_cmd(args ...Value) &MapStringValueCmd {
	return &MapStringValueCmd{
		args: args
	}
}

fn (mut cmd MapStringValueCmd) set_val(mut val map[string]Value) {
	cmd.val = val.move()
}

fn (cmd MapStringValueCmd) val() Value {
	return cmd.val
}

fn (mut cmd MapStringValueCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_map_len()!
	match n {
		int {
			cmd.val = map[string]Value{}
			for i := 0; i < n; i += 1 {
				// so far it works
				k := rd.read_string()!
				match k {
					string {
						v := rd.read_reply() or {
							cmd.val[k] = err as Value // error: cannot implement interface `redict.Value` with a different interface `IError`
							continue
							// if error is a protocol error, set cmd.val[k] as the error.
						}
						cmd.val[k] = v
					}
					else {
						return error(format_error_message('MapStringValueCmd.read_reply: ProtoReader.read_string returned unexpect type'))
					}
				}
			}
		}
		else {
			return RedictError{
				msg: format_error_message('MapStringValueCmd.read_reply: ProtoReader.read_map_len returned unexpect type')
			}
		}
	}
}
