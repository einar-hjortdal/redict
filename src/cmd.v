module redis

import pool.proto
// import time
import x.json2 as json

/*
*
*
* Cmder
*
*
*/

pub interface Cmder {
	name() string
	full_name() string
	args() []json.Any
	cmd_string() string
	arg_string(int) string
	first_key_pos() int
	// read_timeout() time.Duration
	err() string
mut:
	set_first_key_pos(int)
	read_reply(mut rd proto.Reader) !
	set_err(string)
}

fn write_cmds(mut wr proto.Writer, cmds []Cmder) ! {
	for cmd in cmds {
		write_cmd(mut wr, cmd)!
	}
}

fn write_cmd(mut wr proto.Writer, cmd Cmder) ! {
	wr.write_args(cmd.args())!
}

fn cmd_string(cmd Cmder, val json.Any) string {
	mut b := ''

	for i, arg in cmd.args() {
		if i > 0 {
			b += ' '
		}
		b += '${arg}'
	}

	e := cmd.err()
	if e != '' {
		b += ': ${e}'
	} else if val !is json.Null {
		b += ': ${val}'
	}

	return b
}

/*
*
*
* BaseCmd
*
*
*/

struct BaseCmd {
	args []json.Any
mut:
	err     string
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

pub fn (cmd BaseCmd) args() []json.Any {
	return cmd.args
}

fn (cmd BaseCmd) arg_string(pos int) string {
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

fn (cmd BaseCmd) first_key_pos() int {
	return cmd.key_pos
}

fn (mut cmd BaseCmd) set_first_key_pos(key_pos int) {
	cmd.key_pos = key_pos
}

fn (mut cmd BaseCmd) set_err(e string) {
	cmd.err = e
}

pub fn (cmd BaseCmd) err() string {
	return cmd.err
}

/*
*
*
* Cmd
*
*
*/

struct Cmd {
	BaseCmd
mut:
	val json.Any
}

/*
*
*
* IntCmd
*
*
*/

pub struct IntCmd {
	BaseCmd
mut:
	val i64
}

fn new_int_cmd(args ...json.Any) &IntCmd {
	return &IntCmd{
		BaseCmd: BaseCmd{
			args: args
		}
	}
}

pub fn (cmd IntCmd) val() i64 {
	return cmd.val
}

fn (mut cmd IntCmd) set_val(val i64) {
	cmd.val = val
}

fn (cmd IntCmd) result() !i64 {
	if cmd.val != 0 {
		return cmd.val
	} else {
		return error(cmd.err)
	}
}

fn (cmd IntCmd) cmd_string() string {
	return cmd_string(cmd, cmd.val)
}

fn (mut cmd IntCmd) read_reply(mut rd proto.Reader) ! {
	cmd.val = rd.read_int()!
}

/*
*
*
* StatusCmd
*
*
*/

pub struct StatusCmd {
	BaseCmd
mut:
	val string
}

fn new_status_cmd(args ...json.Any) &StatusCmd {
	return &StatusCmd{
		BaseCmd: BaseCmd{
			args: args
		}
	}
}

pub fn (cmd StatusCmd) val() string {
	return cmd.val
}

fn (mut cmd StatusCmd) set_val(val string) {
	cmd.val = val
}

fn (cmd StatusCmd) result() !string {
	if cmd.val != '' {
		return cmd.val
	} else {
		return error(cmd.err)
	}
}

fn (cmd StatusCmd) cmd_string() string {
	return cmd_string(cmd, cmd.val)
}

fn (mut cmd StatusCmd) read_reply(mut rd proto.Reader) ! {
	cmd.val = rd.read_string() or {
		if err.msg() == 'nil' {
			cmd.err = 'nil'
			return
		} else {
			return err
		}
	}
}

/*
*
*
* BoolCmd
*
*
*/

struct BoolCmd {
	BaseCmd
mut:
	val bool
}

fn new_bool_cmd(args ...json.Any) &BoolCmd {
	return &BoolCmd{
		BaseCmd: BaseCmd{
			args: args
		}
	}
}

fn (mut cmd BoolCmd) set_val(val bool) {
	cmd.val = val
}

pub fn (cmd BoolCmd) val() bool {
	return cmd.val
}

fn (cmd BoolCmd) result() !bool {
	if cmd.val != false { // TODO this function should only return the val if command issued without error
		return cmd.val
	} else {
		return error(cmd.err)
	}
}

fn (cmd BoolCmd) cmd_string() string {
	return cmd_string(cmd, cmd.val)
}

fn (mut cmd BoolCmd) read_reply(mut rd proto.Reader) ! {
	cmd.val = rd.read_bool() or {
		// `SET key value NX` returns nil when key already exists.
		// `SETNX key value` returns bool (0/1). So convert nil to bool.
		if err.msg() == 'nil' {
			cmd.val = false
		}
		return err
	}
}

/*
*
*
* StringCmd
*
*
*/

pub struct StringCmd {
	BaseCmd
mut:
	val string
}

fn new_string_cmd(args ...json.Any) &StringCmd {
	return &StringCmd{
		BaseCmd: BaseCmd{
			args: args
		}
	}
}

pub fn (cmd StringCmd) val() string {
	return cmd.val
}

fn (mut cmd StringCmd) set_val(val string) {
	cmd.val = val
}

fn (cmd StringCmd) result() !string {
	if cmd.val != '' {
		return cmd.val
	} else {
		return error(cmd.err)
	}
}

fn (cmd StringCmd) cmd_string() string {
	return cmd_string(cmd, cmd.val)
}

fn (mut cmd StringCmd) read_reply(mut rd proto.Reader) ! {
	cmd.val = rd.read_string() or {
		if err.msg() == 'nil' {
			cmd.err = 'nil'
			return
		} else {
			return err
		}
	}
}

/*
*
*
* MapStringInterfaceCmd
*
*
*/

struct MapStringInterfaceCmd {
	BaseCmd
mut:
	val map[string]json.Any
}

fn new_map_string_interface_cmd(args ...json.Any) &MapStringInterfaceCmd {
	return &MapStringInterfaceCmd{
		BaseCmd: BaseCmd{
			args: args
		}
	}
}

fn (mut cmd MapStringInterfaceCmd) set_val(mut val map[string]json.Any) {
	cmd.val = val.move()
}

pub fn (cmd MapStringInterfaceCmd) val() map[string]json.Any {
	return cmd.val
}

fn (cmd MapStringInterfaceCmd) result() !map[string]json.Any {
	if cmd.err != '' {
		return error(cmd.err)
	} else {
		return cmd.val
	}
}

fn (cmd MapStringInterfaceCmd) cmd_string() string {
	return cmd_string(cmd, cmd.val)
}

fn (mut cmd MapStringInterfaceCmd) read_reply(mut rd proto.Reader) ! {
	n := rd.read_map_len()!
	cmd.val = map[string]json.Any{}
	for i := 0; i < n; i += 1 {
		// so far it works
		k := rd.read_string()!
		v := rd.read_reply() or {
			if err.msg() == 'nil' {
				cmd.val[k] = 'nil'
				continue
			}
			return err
		}
		cmd.val[k] = v
	}
	return
}
