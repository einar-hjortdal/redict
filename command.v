module redict

import time

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

pub struct Cmd {
	BaseCmd
mut:
	val Value
}

fn new_cmd(args ...Value) &Cmd {
	return &Cmd{
		args: args
		val:  Empty{}
	}
}

pub fn (cmd &Cmd) value() Value {
	return cmd.val
}

pub fn (cmd &Cmd) result() !Value {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd Cmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = rd.read_reply()!
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

pub struct IntSliceCmd {
	BaseCmd
mut:
	val []i64
}

fn new_int_slice_cmd(args ...Value) &IntSliceCmd {
	return &IntSliceCmd{
		args: args
	}
}

pub fn (cmd &IntSliceCmd) value() []i64 {
	return cmd.val
}

pub fn (cmd &IntSliceCmd) result() ![]i64 {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd IntSliceCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	cmd.val = []i64{len: 0, cap: n}
	for i := 0; i < n; i++ {
		cmd.val << rd.read_int()!
	}
}

pub struct BoolSliceCmd {
	BaseCmd
mut:
	val []bool
}

fn new_bool_slice_cmd(args ...Value) &BoolSliceCmd {
	return &BoolSliceCmd{
		args: args
	}
}

pub fn (cmd &BoolSliceCmd) value() []bool {
	return cmd.val
}

pub fn (cmd &BoolSliceCmd) result() ![]bool {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd BoolSliceCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	cmd.val = []bool{len: 0, cap: n}
	for i := 0; i < n; i++ {
		cmd.val << rd.read_bool()!
	}
}

pub struct DurationCmd {
	BaseCmd
mut:
	val       time.Duration
	precision time.Duration
}

fn new_duration_cmd(precision time.Duration, args ...Value) &DurationCmd {
	return &DurationCmd{
		args:      args
		precision: precision
	}
}

pub fn (cmd &DurationCmd) value() time.Duration {
	return cmd.val
}

pub fn (cmd &DurationCmd) result() !time.Duration {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd DurationCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_int()!
	match n {
		// -2 if the key does not exist
		// -1 if the key exists, no expire
		-2, -1 {
			cmd.val = time.Duration(n)
		}
		else {
			cmd.val = time.Duration(n) * cmd.precision
		}
	}
}

pub struct MapStringStringCmd {
	BaseCmd
mut:
	val map[string]string
}

fn new_map_string_string_cmd(args ...Value) &MapStringStringCmd {
	return &MapStringStringCmd{
		args: args
	}
}

pub fn (cmd &MapStringStringCmd) value() map[string]string {
	return cmd.val
}

pub fn (cmd &MapStringStringCmd) result() !map[string]string {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd MapStringStringCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_map_len()!

	for i := 0; i < n; i++ {
		key := rd.read_string()!
		value := rd.read_string()!
		cmd.val[key] = value
	}
}

pub struct CommandInfo {
	name          string
	arity         i8
	flags         []string
	acl_flags     []string
	first_key_pos i8
	last_key_pos  i8
	step_count    i8
	read_only     bool
}

struct CommandsInfoCmd {
	BaseCmd
mut:
	val map[string]CommandInfo
}

fn new_commands_info_cmd(args ...Value) &CommandsInfoCmd {
	return &CommandsInfoCmd{
		args: args
	}
}

pub fn (cmd &CommandsInfoCmd) value() map[string]CommandInfo {
	return cmd.val
}

pub fn (cmd &CommandsInfoCmd) result() !map[string]CommandInfo {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd CommandsInfoCmd) read_reply(mut rd ProtoReader) ! {
	num_arg_redict5 := 6
	num_arg_redict6 := 7
	num_arg_redict7 := 10

	n := rd.read_array_len()!

	for i := 0; i < n; i++ {
		nn := rd.read_array_len()!
		match nn {
			num_arg_redict5, num_arg_redict6, num_arg_redict7 {}
			else { return error(format_error_message('got ${n} elements in COMMAND reply, expected 6/7/10"')) }
		}

		name := rd.read_string()!
		arity := rd.read_int()!

		flag_len := rd.read_array_len()!
		mut read_only := false
		mut flags := []string{len: flag_len}
		for f := 0; f < flag_len; f++ {
			s := rd.read_string() or {
				if is_nil(err) { '' }
				return err
			}

			if s == 'readonly' {
				read_only = true
			}

			flags[f] = s
		}

		first_key_pos := rd.read_int()!
		last_key_pos := rd.read_int()!
		step_count := rd.read_int()!

		mut acl_flags := []string{}
		if nn >= num_arg_redict6 {
			acl_flags_len := rd.read_array_len()!
			acl_flags = []string{len: acl_flags_len}
			for f := 0; f < acl_flags_len; f++ {
				s := rd.read_string() or {
					if is_nil(err) { '' }
					return err
				}
				acl_flags[f] = s
			}
		}

		if nn >= num_arg_redict7 {
			rd.discard_next()!
			rd.discard_next()!
			rd.discard_next()!
		}

		cmd.val[name] = CommandInfo{
			name:          name
			arity:         i8(arity)
			flags:         flags
			acl_flags:     acl_flags
			first_key_pos: i8(first_key_pos)
			last_key_pos:  i8(last_key_pos)
			step_count:    i8(step_count)
			read_only:     read_only
		}
	}
}

pub struct KeyFlags {
pub:
	key   string
	flags []string
}

struct KeyFlagsCmd {
	BaseCmd
mut:
	val []KeyFlags
}

fn new_key_flags_cmd(args ...Value) &KeyFlagsCmd {
	return &KeyFlagsCmd{
		args: args
	}
}

pub fn (cmd &KeyFlagsCmd) value() []KeyFlags {
	return cmd.val
}

pub fn (cmd &KeyFlagsCmd) result() ![]KeyFlags {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd KeyFlagsCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	cmd.val = []KeyFlags{len: 0, cap: n}
	if n == 0 {
		return
	}

	for i := 0; i < n; i++ {
		rd.read_fixed_array_len(2)!
		key := rd.read_string()!

		flags_len := rd.read_array_len()!
		mut flags := []string{len: 0, cap: flags_len}
		for j := 0; j < flags_len; j++ {
			flags << rd.read_string()!
		}

		cmd.val << KeyFlags{
			key:   key
			flags: flags
		}
	}
}
