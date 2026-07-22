module redict

import time

interface Cmdable {
	BitMapCmdable
	GenericCmdable
	HashCmdable
	ListCmdable
	SetCmdable
	StringCmdable
	command() &CommandsInfoCmd
	command_list() &StringSliceCmd
	command_list_filterby_module(module string) &StringSliceCmd
	command_list_filterby_aclcat(aclcat string) &StringSliceCmd
	command_list_filterby_pattern(pattern string) &StringSliceCmd
	command_getkeys(commands ...Value) &StringSliceCmd
	command_getkeysandflags(commands ...Value) &KeyFlagsCmd
	echo(message Value) &StringCmd
	ping() &StatusCmd
	// quit() &StatusCmd
	bgrewriteaof() &StatusCmd
	bgsave() &StatusCmd
	client_getname() &StringCmd
	client_id() &IntCmd
	client_info() &ClientInfoCmd
	client_kill_filer(keys ...string) &IntCmd
	client_kill(ip_port string) &StatusCmd
	client_list() &StringCmd
	client_pause(d time.Duration) &BoolCmd
	client_unblock_error(id i64) &IntCmd
	client_unblock(id i64) &IntCmd
	client_unpause() &BoolCmd
	// config_et
	// config_reset_stat
	// config_rewrite
	// config_set
	// dbsize
	// debug_object
	// flushall
	// flushall_async
	// flushdb
	// flushdb_async
	// info
	// info_map
	// lastsave
	// memory_usage
	// save
	// shutdown
	// shutdown_nosave
	// shutdown_save
	// slaveof
	// slowlog_get
	// time
}

type CmdableFn = fn (mut cmd Cmder) !

pub fn (c CmdableFn) command() &CommandsInfoCmd {
	mut cmd := new_commands_info_cmd('COMMAND')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) command_list() &StringSliceCmd {
	mut cmd := new_string_slice_cmd('COMMAND', 'LIST')
	c(mut cmd) or {}
	return cmd
}

fn (c CmdableFn) command_list_filerby(mode string, parameter string) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('COMMAND', 'LIST', 'FILERBY', mode, parameter)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) command_list_filerby_module(redict_module string) &StringSliceCmd {
	return c.command_list_filerby('MODULE', redict_module)
}

pub fn (c CmdableFn) command_list_filerby_aclcat(aclcat string) &StringSliceCmd {
	return c.command_list_filerby('ACLCAT', aclcat)
}

pub fn (c CmdableFn) command_list_filerby_pattern(pattern string) &StringSliceCmd {
	return c.command_list_filerby('PATTERN', pattern)
}

pub fn (c CmdableFn) command_getkeys(commands ...Value) &StringSliceCmd {
	mut args := []Value{len: 0, cap: commands.len + 2, init: Value(Empty{})}
	args << 'COMMAND'
	args << 'GETKEYS'
	args << commands

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) command_getkeysandflags(commands ...Value) &KeyFlagsCmd {
	mut args := []Value{len: 0, cap: commands.len + 2, init: Value(Empty{})}
	args << 'COMMAND'
	args << 'GETKEYSANDFLAGS'
	args << commands

	mut cmd := new_key_flags_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) echo(message Value) &StringCmd {
	mut cmd := new_string_cmd('ECHO', message)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) ping() &StatusCmd {
	mut cmd := new_status_cmd('PING')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) bgrewriteaof() &StatusCmd {
	mut cmd := new_status_cmd('BGREWRITEAOF')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) bgsave() &StatusCmd {
	mut cmd := new_status_cmd('BGSAVE')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_getname() &StringCmd {
	mut cmd := new_string_cmd('CLIENT', 'GETNAME')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_id() &IntCmd {
	mut cmd := new_int_cmd('CLIENT', 'ID')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_info() &ClientInfoCmd {
	mut cmd := new_client_info_cmd('CLIENT', 'INFO')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_kill_filter(keys ...string) &IntCmd {
	mut args := []Value{len: 0, cap: keys.len + 2, init: Value(Empty{})}
	args << 'CLIENT'
	args << 'KILL'
	args << keys

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_kill(ip_port string) &StatusCmd {
	mut cmd := new_status_cmd('CLIENT', 'KILL', ip_port)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_list() &StringCmd {
	mut cmd := new_string_cmd('CLIENT', 'LIST')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_pause(d time.Duration) &BoolCmd {
	mut cmd := new_bool_cmd('CLIENT', 'PAUSE', format_ms(d))
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_unblock_error(id i64) &IntCmd {
	mut cmd := new_int_cmd('CLIENT', 'UNBLOCK', id, 'ERROR')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_unblock(id i64) &IntCmd {
	mut cmd := new_int_cmd('CLIENT', 'UNBLOCK', id)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) client_unpause() &BoolCmd {
	mut cmd := new_bool_cmd('CLIENT', 'UNPAUSE')
	c(mut cmd) or {}
	return cmd
}
