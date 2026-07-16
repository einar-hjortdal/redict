module redict

interface Cmdable {
	BitMapCmdable
	GenericCmdable
	HashCmdable
	SetCmdable
	StringCmdable
	command() &CommandsInfoCmd
	command_getkeys(commands ...Value) &StringSliceCmd
	client_getname() &StringCmd
	echo(message Value) &StringCmd
	ping() &StatusCmd
}

type CmdableFn = fn (mut cmd Cmder) !

pub fn (c CmdableFn) command() &CommandsInfoCmd {
	mut cmd := new_commands_info_cmd('COMMAND')
	c(mut cmd) or {}
	return cmd
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

pub fn (c CmdableFn) client_getname() &StringCmd {
	mut cmd := new_string_cmd('CLIENT', 'GETNAME')
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
