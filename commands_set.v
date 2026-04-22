module redict

import arrays

pub interface SetCmdable {
	sadd(key string, members ...Value) &IntCmd
	smembers(key string) &StringSliceCmd
	srem(key string, members ...Value) &IntCmd
}

pub fn (c CmdableFn) sadd(key string, members ...Value) &IntCmd {
	mut args := []Value{len: 2, init: Value('')}
	args[0] = 'sadd'
	args[1] = key
	args = arrays.concat(args, ...members)
	cmd := new_int_cmd(...args)
	c(cmd) or {}
	return cmd
}

pub fn (c CmdableFn) smembers(key string) &StringSliceCmd {
	cmd := new_string_slice_cmd('smembers', key)
	c(cmd) or {}
	return cmd
}

pub fn (c CmdableFn) srem(key string, members ...Value) &IntCmd {
	mut args := []Value{len: 2, init: Value('')}
	args[0] = 'srem'
	args[1] = key
	args = arrays.concat(args, ...members)
	cmd := new_int_cmd(...args)
	c(cmd) or {}
	return cmd
}

