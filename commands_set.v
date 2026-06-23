module redict

import arrays

pub interface SetCmdable {
	sadd(key string, members ...Value) &IntCmd
	sismember(key string, member Value) &BoolCmd
	smembers(key string) &StringSliceCmd
	srem(key string, members ...Value) &IntCmd
}

pub fn (c CmdableFn) sadd(key string, members ...Value) &IntCmd {
	mut args := []Value{len: 2, init: Value('')}
	args[0] = 'sadd'
	args[1] = key
	args = arrays.concat(args, ...members)
	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) sismember(key string, member Value) &BoolCmd {
	mut cmd := new_bool_cmd('sismember', key, member)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) smembers(key string) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('smembers', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) srem(key string, members ...Value) &IntCmd {
	mut args := []Value{len: 2, init: Value('')}
	args[0] = 'srem'
	args[1] = key
	args = arrays.concat(args, ...members)
	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}
