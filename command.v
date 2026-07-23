module redict

import time
import strconv

pub interface Cmder {
	name() string
	full_name() string
	args() []Value
	string_arg(pos int) string
	first_key_pos() int
	read_timeout() ?time.Duration
	error() !
mut:
	read_reply(mut rd ProtoReader) !
	set_first_key_pos(key_pos int)
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
	error        ?IError
	key_pos      int
	read_timeout ?time.Duration
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

fn (cmd BaseCmd) read_timeout() ?time.Duration {
	return cmd.read_timeout
}

fn (mut cmd BaseCmd) set_read_timeout(d time.Duration) {
	cmd.read_timeout = d
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
pub:
	name          string
	arity         i8
	flags         []string
	acl_flags     []string
	first_key_pos i8
	last_key_pos  i8
	step_count    i8
	read_only     bool
}

pub struct CommandsInfoCmd {
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
			else {
				return new_redict_error('got ${n} elements in COMMAND reply, expected 6/7/10"')
			}
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

pub struct KeyFlagsCmd {
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

pub struct ClientInfo {
pub mut:
	id                   i64
	addr                 string
	l_addr               string
	fd                   i64
	name                 string
	age                  time.Duration
	idle                 time.Duration
	flags                u64
	db                   int
	sub                  int
	p_sub                int
	s_sub                int
	multi                int
	watch                int
	query_buf            int
	query_buf_free       int
	argv_mem             int
	multi_mem            int
	buffer_size          int
	buffer_peak          int
	output_buffer_length int
	output_list_length   int
	output_memory        int
	total_memory         int
	events               string
	last_cmd             string
	user                 string
	redir                i64
	resp                 int
	lib_name             string
	lib_ver              string
}

fn parse_client_info(s string) !&ClientInfo {
	mut res := &ClientInfo{}
	parts := s.split(' ')
	for _, part in parts {
		kv := part.split('=')
		if kv.len != 2 {
			return new_redict_error('unexpected client info data (${s})')
		}

		key, val := kv[0], kv[1]
		match key {
			'id' {
				res.id = strconv.parse_int(val, 10, 64)!
			}
			'addr' {
				res.addr = val
			}
			'laddr' {
				res.l_addr = val
			}
			'fd' {
				res.fd = strconv.parse_int(val, 10, 64)!
			}
			'name' {
				res.name = val
			}
			'age' {
				age := strconv.atoi(val)!
				res.age = age * time.second
			}
			'idle' {
				idle := strconv.atoi(val)!
				res.age = idle * time.second
			}
			'flags' {
				if val == 'N' {
					break
				}

				for i := 0; i < val.len; i++ {
					match val[i] {
						`S` {
							res.flags |= client_slave
						}
						`O` {
							res.flags |= client_slave | client_monitor
						}
						`M` {
							res.flags |= client_master
						}
						`P` {
							res.flags |= client_pub_sub
						}
						`x` {
							res.flags |= client_multi
						}
						`b` {
							res.flags |= client_blocked
						}
						`t` {
							res.flags |= client_tracking
						}
						`R` {
							res.flags |= client_tracking_broken_redir
						}
						`B` {
							res.flags |= client_tracking_bcast
						}
						`d` {
							res.flags |= client_dirty_cas
						}
						`c` {
							res.flags |= client_close_after_command
						}
						`u` {
							res.flags |= client_un_blocked
						}
						`A` {
							res.flags |= client_close_asap
						}
						`U` {
							res.flags |= client_unix_socket
						}
						`r` {
							res.flags |= client_read_only
						}
						`e` {
							res.flags |= client_no_evict
						}
						`T` {
							res.flags |= client_no_touch
						}
						else {
							return new_redict_error('unexpected client info flags(${part})')
						}
					}
				}
			}
			'db' {
				res.db = strconv.atoi(val)!
			}
			'sub' {
				res.sub = strconv.atoi(val)!
			}
			'psub' {
				res.p_sub = strconv.atoi(val)!
			}
			'ssub' {
				res.s_sub = strconv.atoi(val)!
			}
			'multi' {
				res.multi = strconv.atoi(val)!
			}
			'watch' {
				res.watch = strconv.atoi(val)!
			}
			'qbuf' {
				res.query_buf = strconv.atoi(val)!
			}
			'qbuf-free' {
				res.query_buf_free = strconv.atoi(val)!
			}
			'argv-mem' {
				res.argv_mem = strconv.atoi(val)!
			}
			'multi-mem' {
				res.multi_mem = strconv.atoi(val)!
			}
			'rbs' {
				res.buffer_size = strconv.atoi(val)!
			}
			'rbp' {
				res.buffer_peak = strconv.atoi(val)!
			}
			'obl' {
				res.output_buffer_length = strconv.atoi(val)!
			}
			'oll' {
				res.output_list_length = strconv.atoi(val)!
			}
			'omem' {
				res.output_memory = strconv.atoi(val)!
			}
			'tot-mem' {
				res.total_memory = strconv.atoi(val)!
			}
			'events' {
				res.events = val
			}
			'cmd' {
				res.last_cmd = val
			}
			'user' {
				res.user = val
			}
			'redir' {
				res.redir = strconv.parse_int(val, 10, 64)!
			}
			'resp' {
				res.resp = strconv.atoi(val)!
			}
			'lib-name' {
				res.lib_name = val
			}
			'lib-ver' {
				res.lib_ver = val
			}
			else {
				return new_redict_error('unexpected client info key ${key}')
			}
		}
	}
	return res
}

pub struct ClientInfoCmd {
	BaseCmd
mut:
	val ClientInfo
}

fn new_client_info_cmd(args ...Value) &ClientInfoCmd {
	return &ClientInfoCmd{
		args: args
	}
}

pub fn (cmd &ClientInfoCmd) value() ClientInfo {
	return cmd.val
}

pub fn (cmd &ClientInfoCmd) result() !ClientInfo {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd ClientInfoCmd) read_reply(mut rd ProtoReader) ! {
	s := rd.read_string()!
	cmd.val = parse_client_info(s.trim_space())!
}

pub struct KeyValuesCmd {
	BaseCmd
mut:
	key string
	val []string
}

fn new_key_values_cmd(args ...Value) &KeyValuesCmd {
	return &KeyValuesCmd{
		args: args
	}
}

pub fn (cmd &KeyValuesCmd) value() (string, []string) {
	return cmd.key, cmd.val
}

pub fn (cmd &KeyValuesCmd) result() !(string, []string) {
	error := cmd.error or { return cmd.key, cmd.val }
	return error
}

fn (mut cmd KeyValuesCmd) read_reply(mut rd ProtoReader) ! {
	rd.read_fixed_array_len(2)!
	cmd.key = rd.read_string()!
	n := rd.read_array_len()!
	cmd.val = []string{len: 0, cap: n}
	for i := 0; i < n; i++ {
		cmd.val << rd.read_string()!
	}
}

pub struct Xmessage {
	id     string
	values map[string]Value
}

pub struct XmessageSliceCmd {
	BaseCmd
mut:
	val []Xmessage
}

fn new_xmessage_slice_cmd(args ...Value) &XmessageSliceCmd {
	return &XmessageSliceCmd{
		args: args
	}
}

pub fn (cmd &XmessageSliceCmd) value() []Xmessage {
	return cmd.val
}

pub fn (cmd &XmessageSliceCmd) result() ![]Xmessage {
	error := cmd.error or { return cmd.val }
	return error
}

fn string_value_map_parser(mut rd ProtoReader) !map[string]Value {
	n := rd.read_map_len()!
	mut res := map[string]Value{}
	for i := 0; i < n; i++ {
		key := rd.read_string()!
		value := rd.read_string()!
		res[key] = value
	}
	return res
}

fn read_xmessage(mut rd ProtoReader) !Xmessage {
	rd.read_fixed_array_len(2)!
	id := rd.read_string()!
	v := string_value_map_parser(mut rd) or {
		if is_nil(err) {
			return Xmessage{
				id: id
			}
		}
		return err
	}

	return Xmessage{
		id:     id
		values: v
	}
}

fn read_xmessage_slice(mut rd ProtoReader) ![]Xmessage {
	n := rd.read_array_len()!
	mut res := []Xmessage{len: 0, cap: n}
	for i := 0; i < n; i++ {
		res << read_xmessage(mut rd)!
	}
	return res
}

fn (mut cmd XmessageSliceCmd) read_reply(mut rd ProtoReader) ! {
	cmd.val = read_xmessage_slice(mut rd)!
}

pub struct Xstream {
pub:
	stream   string
	messages []Xmessage
}

pub struct XstreamSliceCmd {
	BaseCmd
mut:
	val []Xstream
}

fn new_xstream_slice_cmd(args ...Value) &XstreamSliceCmd {
	return &XstreamSliceCmd{
		args: args
	}
}

pub fn (cmd &XstreamSliceCmd) value() []Xstream {
	return cmd.val
}

pub fn (cmd &XstreamSliceCmd) result() ![]Xstream {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd XstreamSliceCmd) read_reply(mut _ ProtoReader) ! {
	// t := rd.peek_reply_type()!
	return new_redict_error('Not implemented: need to be able to tell maps and arrays apart for this command.')
}

pub struct XautoclaimCmd {
	BaseCmd
mut:
	start string
	val   []Xmessage
}

fn new_xautoclaim_cmd(args ...Value) &XautoclaimCmd {
	return &XautoclaimCmd{
		args: args
	}
}

pub fn (cmd &XautoclaimCmd) value() []Xmessage {
	return cmd.val
}

pub fn (cmd &XautoclaimCmd) result() ![]Xmessage {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd XautoclaimCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	match n {
		2, 3 {}
		else {
			return new_redict_error('got ${n} elements in XAUTOCLAIM reply, expected 2 or 3')
		}
	}

	cmd.start = rd.read_string()!
	cmd.val = read_xmessage_slice(mut rd)!

	if n > 2 {
		rd.discard_next()!
	}
}

pub struct XautoclaimJustidCmd {
	BaseCmd
mut:
	start string
	val   []string
}

fn new_xautoclaim_justid_cmd(args ...Value) &XautoclaimJustidCmd {
	return &XautoclaimJustidCmd{
		args: args
	}
}

pub fn (cmd &XautoclaimJustidCmd) value() ([]string, string) {
	return cmd.val, cmd.start
}

pub fn (cmd &XautoclaimJustidCmd) result() !([]string, string) {
	error := cmd.error or { return cmd.val, cmd.start }
	return error
}

fn (mut cmd XautoclaimJustidCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	match n {
		2, 3 {}
		else {
			return new_redict_error('got ${n} elements in XAUTOCLAIM reply, expected 2 or 3')
		}
	}

	cmd.start = rd.read_string()!
	nn := rd.read_array_len()!
	cmd.val = []string{len: 0, cap: nn}
	for i := 0; i < nn; i++ {
		cmd.val << rd.read_string()!
	}

	if n > 2 {
		rd.discard_next()!
	}
}

pub struct XinfoConsumer {
pub:
	name     string
	pending  i64
	idle     time.Duration
	inactive time.Duration
}

pub struct XinfoConsumersCmd {
	BaseCmd
mut:
	val []XinfoConsumer
}

fn new_xinfo_consumers_cmd(args ...Value) &XinfoConsumersCmd {
	return &XinfoConsumersCmd{
		args: args
	}
}

pub fn (cmd &XinfoConsumersCmd) value() []XinfoConsumer {
	return cmd.val
}

pub fn (cmd &XinfoConsumersCmd) result() ![]XinfoConsumer {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd XinfoConsumersCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	cmd.val = []XinfoConsumer{len: 0, cap: n}
	for i := 0; i < n; i++ {
		nn := rd.read_map_len()!

		mut name := ''
		mut pending := i64(0)
		mut idle := time.Duration(0)
		mut inactive := time.Duration(0)
		for f := 0; f < nn; f++ {
			key := rd.read_string()!
			match key {
				'name' {
					name = rd.read_string()!
				}
				'pending' {
					pending = rd.read_int()!
				}
				'idle' {
					idle = rd.read_int()!
				}
				'inactive' {
					inactive = rd.read_int()!
				}
				else {
					return new_redict_error('unexpected content ${key} in XINFO CONSUMERS reply')
				}
			}
		}

		cmd.val << XinfoConsumer{
			name:     name
			pending:  pending
			idle:     idle
			inactive: inactive
		}
	}
}

struct XinfoGroups {
pub:
	name              string
	consumers         i64
	pending           i64
	last_delivered_id string
	entries_read      i64
	lag               i64
}

pub struct XinfoGroupsCmd {
	BaseCmd
mut:
	val []XinfoGroups
}

fn new_xinfo_groups_cmd(args ...Value) &XinfoGroupsCmd {
	return &XinfoGroupsCmd{
		args: args
	}
}

pub fn (cmd &XinfoGroupsCmd) value() []XinfoGroups {
	return cmd.val
}

pub fn (cmd &XinfoGroupsCmd) result() ![]XinfoGroups {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd XinfoGroupsCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	cmd.val = []XinfoGroups{len: 0, cap: n}
	for i := 0; i < n; i++ {
		nn := rd.read_map_len()!

		mut name := ''
		mut consumers := i64(0)
		mut pending := i64(0)
		mut last_delivered_id := ''
		mut entries_read := i64(0)
		mut lag := i64(0)

		for f := 0; f < nn; f++ {
			key := rd.read_string()!
			match key {
				'name' {
					name = rd.read_string()!
				}
				'consumers' {
					consumers = rd.read_int()!
				}
				'pending' {
					pending = rd.read_int()!
				}
				'last-delivered-id' {
					last_delivered_id = rd.read_string()!
				}
				'entries-read' {
					entries_read = rd.read_int()!
				}
				'lag' {
					lag = rd.read_int()!
				}
				else {
					return new_redict_error('unexpected content ${key} in XINFO GROUPS reply')
				}
			}
		}

		cmd.val << XinfoGroups{
			name:              name
			consumers:         consumers
			pending:           pending
			last_delivered_id: last_delivered_id
			entries_read:      entries_read
			lag:               lag
		}
	}
}

struct XinfoStream {
pub:
	length                  i64
	radix_tree_keys         i64
	radix_tree_nodes        i64
	groups                  i64
	last_generated_id       string
	max_deleted_entry_id    string
	entries_added           i64
	first_entry             Xmessage
	last_entry              Xmessage
	recorded_first_entry_id string
}

pub struct XinfoStreamCmd {
	BaseCmd
mut:
	val XinfoStream
}

fn new_xinfo_stream_cmd(args ...Value) &XinfoStreamCmd {
	return &XinfoStreamCmd{
		args: args
	}
}

pub fn (cmd &XinfoStreamCmd) value() XinfoStream {
	return cmd.val
}

pub fn (cmd &XinfoStreamCmd) result() !XinfoStream {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd XinfoStreamCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_map_len()!

	mut length := i64(0)
	mut radix_tree_keys := i64(0)
	mut radix_tree_nodes := i64(0)
	mut groups := i64(0)
	mut last_generated_id := ''
	mut max_deleted_entry_id := ''
	mut entries_added := i64(0)
	mut first_entry := Xmessage{}
	mut last_entry := Xmessage{}
	mut recorded_first_entry_id := ''

	for i := 0; i < n; i++ {
		key := rd.read_string()!
		match key {
			'length' {
				length = rd.read_int()!
			}
			'radix-tree-keys' {
				radix_tree_keys = rd.read_int()!
			}
			'radix-tree-nodes' {
				radix_tree_nodes = rd.read_int()!
			}
			'groups' {
				groups = rd.read_int()!
			}
			'last-generated-id' {
				last_generated_id = rd.read_string()!
			}
			'max-deleted-entry-id' {
				max_deleted_entry_id = rd.read_string()!
			}
			'entries-added' {
				entries_added = rd.read_int()!
			}
			'first-entry' {
				first_entry = read_xmessage(mut rd)!
			}
			'last-entry' {
				last_entry = read_xmessage(mut rd)!
			}
			'recorded-first-entry-id' {
				recorded_first_entry_id = rd.read_string()!
			}
			else {
				return new_redict_error('unexpected content ${key} in XINFO STREAM reply')
			}
		}
	}

	cmd.val = XinfoStream{
		length:                  length
		radix_tree_keys:         radix_tree_keys
		radix_tree_nodes:        radix_tree_nodes
		groups:                  groups
		last_generated_id:       last_generated_id
		max_deleted_entry_id:    max_deleted_entry_id
		entries_added:           entries_added
		first_entry:             first_entry
		last_entry:              last_entry
		recorded_first_entry_id: recorded_first_entry_id
	}
}

pub struct XinfoStreamGroupPending {
pub:
	id             string
	consumer       string
	delivery_time  time.Time
	delivery_count i64
}

pub struct XinfoStreamConsumerPending {
pub:
	id             string
	delivery_time  time.Time
	delivery_count i64
}

pub struct XinfoStreamConsumer {
pub:
	name        string
	seen_time   time.Time
	active_time time.Time
	pel_count   i64
	pending     []XinfoStreamConsumerPending
}

pub struct XinfoStreamGroup {
pub:
	name              string
	last_delivered_id string
	entries_read      i64
	lag               i64
	pel_count         i64
	pending           []XinfoStreamGroupPending
	consumers         []XinfoStreamConsumer
}

pub struct XinfoStreamFull {
pub:
	length                  i64
	radix_tree_keys         i64
	radix_tree_nodes        i64
	last_generated_id       string
	max_deleted_entry_id    string
	entries_added           i64
	entries                 []Xmessage
	groups                  []XinfoStreamGroup
	recorded_first_entry_id string
}

pub struct XinfoStreamFullCmd {
	BaseCmd
mut:
	val XinfoStreamFull
}

fn new_xinfo_stream_full_cmd(args ...Value) &XinfoStreamFullCmd {
	return &XinfoStreamFullCmd{
		args: args
	}
}

pub fn (cmd &XinfoStreamFullCmd) value() XinfoStreamFull {
	return cmd.val
}

pub fn (cmd &XinfoStreamFullCmd) result() !XinfoStreamFull {
	error := cmd.error or { return cmd.val }
	return error
}

fn read_xinfo_stream_group_pending(mut rd ProtoReader) ![]XinfoStreamGroupPending {
	n := rd.read_array_len()!
	mut pending := []XinfoStreamGroupPending{len: 0, cap: n}
	for i := 0; i < n; i++ {
		rd.read_fixed_array_len(4)!
		id := rd.read_string()!
		consumer := rd.read_string()!

		delivery := rd.read_int()!
		sec := delivery / 1000
		nsec := int(delivery % 1000 * time.millisecond)
		delivery_time := time.unix_nanosecond(sec, nsec)

		delivery_count := rd.read_int()!

		pending << XinfoStreamGroupPending{
			id:             id
			consumer:       consumer
			delivery_time:  delivery_time
			delivery_count: delivery_count
		}
	}
	return pending
}

fn read_xinfo_stream_consumers_pending(mut rd ProtoReader) ![]XinfoStreamConsumerPending {
	n := rd.read_array_len()!
	mut pending := []XinfoStreamConsumerPending{len: 0, cap: n}
	for i := 0; i < n; i++ {
		rd.read_fixed_array_len(3)!
		id := rd.read_string()!

		delivery := rd.read_int()!
		sec := delivery / 1000
		nsec := int(delivery % 1000 * time.millisecond)
		delivery_time := time.unix_nanosecond(sec, nsec)

		delivery_count := rd.read_int()!

		pending << XinfoStreamConsumerPending{
			id:             id
			delivery_time:  delivery_time
			delivery_count: delivery_count
		}
	}
	return pending
}

fn read_xinfo_stream_consumers(mut rd ProtoReader) ![]XinfoStreamConsumer {
	n := rd.read_array_len()!
	mut consumers := []XinfoStreamConsumer{len: 0, cap: n}
	for i := 0; i < n; i++ {
		nn := rd.read_map_len()!
		for f := 0; f < nn; f++ {
			mut name := ''
			mut seen_time := time.Time{}
			mut active_time := time.Time{}
			mut pel_count := i64(0)
			mut pending := []XinfoStreamConsumerPending{}

			key := rd.read_string()!
			match key {
				'name' {
					name = rd.read_string()!
				}
				'seen-time' {
					t := rd.read_int()!
					seen_time = time.unix_milli(t)
				}
				'active-time' {
					t := rd.read_int()!
					active_time = time.unix_milli(t)
				}
				'pel-count' {
					pel_count = rd.read_int()!
				}
				'pending' {
					pending = read_xinfo_stream_consumers_pending(mut rd)!
				}
				else {
					return new_redict_error('unexpected key ${key} in XINFO STREAM FULL reply')
				}
			}

			consumers << XinfoStreamConsumer{
				name:        name
				seen_time:   seen_time
				active_time: active_time
				pel_count:   pel_count
				pending:     pending
			}
		}
	}
	return consumers
}

fn read_stream_groups(mut rd ProtoReader) ![]XinfoStreamGroup {
	n := rd.read_array_len()!
	mut groups := []XinfoStreamGroup{len: 0, cap: n}
	for i := 0; i < n; i++ {
		nn := rd.read_map_len()!

		mut name := ''
		mut last_delivered_id := ''
		mut entries_read := i64(0)
		mut lag := i64(0)
		mut pel_count := i64(0)
		mut pending := []XinfoStreamGroupPending{}
		mut consumers := []XinfoStreamConsumer{}

		for f := 0; f < nn; f++ {
			key := rd.read_string()!
			match key {
				'name' {
					name = rd.read_string()!
				}
				'last-delivered-id' {
					last_delivered_id = rd.read_string()!
				}
				'entries-read' {
					entries_read = rd.read_int()!
				}
				'lag' {
					lag = rd.read_int()!
				}
				'pel-count' {
					pel_count = rd.read_int()!
				}
				'pending' {
					pending = read_xinfo_stream_group_pending(mut rd)!
				}
				'consumers' {
					consumers = read_xinfo_stream_consumers(mut rd)!
				}
				else {
					return new_redict_error('unexpected key ${key} in XINFO STREAM FULL reply')
				}
			}
		}

		groups << XinfoStreamGroup{
			name:              name
			last_delivered_id: last_delivered_id
			entries_read:      entries_read
			lag:               lag
			pel_count:         pel_count
			pending:           pending
			consumers:         consumers
		}
	}

	return groups
}

fn (mut cmd XinfoStreamFullCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_map_len()!

	mut length := i64(0)
	mut radix_tree_keys := i64(0)
	mut radix_tree_nodes := i64(0)
	mut last_generated_id := ''
	mut max_deleted_entry_id := ''
	mut entries_added := i64(0)
	mut entries := []Xmessage{}
	mut groups := []XinfoStreamGroup{}
	mut recorded_first_entry_id := ''

	for i := 0; i < n; i++ {
		key := rd.read_string()!
		match key {
			'length' {
				length = rd.read_int()!
			}
			'radix-tree-keys' {
				radix_tree_keys = rd.read_int()!
			}
			'radix-tree-nodes' {
				radix_tree_nodes = rd.read_int()!
			}
			'last-generated-id' {
				last_generated_id = rd.read_string()!
			}
			'max-deleted-entry-id' {
				max_deleted_entry_id = rd.read_string()!
			}
			'entries-added' {
				entries_added = rd.read_int()!
			}
			'entries' {
				entries = read_xmessage_slice(mut rd)!
			}
			'groups' {
				groups = read_stream_groups(mut rd)!
			}
			'recorded-first-entry-id' {
				recorded_first_entry_id = rd.read_string()!
			}
			else {
				return new_redict_error('unexpected key ${key} in XINFO STREAM FULL reply')
			}
		}
	}

	cmd.val = XinfoStreamFull{
		length:                  length
		radix_tree_keys:         radix_tree_keys
		radix_tree_nodes:        radix_tree_nodes
		last_generated_id:       last_generated_id
		max_deleted_entry_id:    max_deleted_entry_id
		entries_added:           entries_added
		entries:                 entries
		groups:                  groups
		recorded_first_entry_id: recorded_first_entry_id
	}
}

struct Xpending {
pub:
	count     i64
	lower     string
	higher    string
	consumers map[string]i64
}

pub struct XpendingCmd {
	BaseCmd
mut:
	val Xpending
}

fn new_xpending_cmd(args ...Value) &XpendingCmd {
	return &XpendingCmd{
		args: args
	}
}

pub fn (cmd &XpendingCmd) value() Xpending {
	return cmd.val
}

pub fn (cmd &XpendingCmd) result() !Xpending {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd XpendingCmd) read_reply(mut rd ProtoReader) ! {
	rd.read_fixed_array_len(4)!

	count := rd.read_int()!
	lower := rd.read_string()!
	higher := rd.read_string()!
	mut consumers := map[string]i64{}

	n := rd.read_array_len()!
	for i := 0; i < n; i++ {
		rd.read_fixed_array_len(2)!
		consumer_name := rd.read_string()!
		consumer_pending := rd.read_int()!
		consumers[consumer_name] = consumer_pending
	}

	cmd.val = Xpending{
		count:     count
		lower:     lower
		higher:    higher
		consumers: consumers
	}
}

pub struct XpendingExtended {
pub:
	id          string
	consumer    string
	idle        time.Duration
	retry_count i64
}

pub struct XpendingExtendedCmd {
	BaseCmd
mut:
	val []XpendingExtended
}

fn new_xpending_extended_cmd(args ...Value) &XpendingExtendedCmd {
	return &XpendingExtendedCmd{
		args: args
	}
}

pub fn (cmd &XpendingExtendedCmd) value() []XpendingExtended {
	return cmd.val
}

pub fn (cmd &XpendingExtendedCmd) result() ![]XpendingExtended {
	error := cmd.error or { return cmd.val }
	return error
}

fn (mut cmd XpendingExtendedCmd) read_reply(mut rd ProtoReader) ! {
	n := rd.read_array_len()!
	cmd.val = []XpendingExtended{len: 0, cap: n}
	for i := 0; i < n; i++ {
		rd.read_fixed_array_len(4)!
		id := rd.read_string()!
		consumer := rd.read_string()!
		idle := rd.read_int()!
		retry_count := rd.read_int()!

		cmd.val << XpendingExtended{
			id:          id
			consumer:    consumer
			idle:        idle
			retry_count: retry_count
		}
	}
}
