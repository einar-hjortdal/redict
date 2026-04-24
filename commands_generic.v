module redict

import time
import arrays

// https://redict.io/docs/commands/#generic
pub interface GenericCmdable {
	del(keys ...string) &IntCmd
	expire(key string, expiration time.Duration) &BoolCmd
	expire_nx(key string, expiration time.Duration) &BoolCmd
	expire_xx(key string, expiration time.Duration) &BoolCmd
	expire_gt(key string, expiration time.Duration) &BoolCmd
	expire_lt(key string, expiration time.Duration) &BoolCmd
}

pub fn (c CmdableFn) del(keys ...string) &IntCmd {
	mut args := []Value{len: 1 + keys.len, init: Value('')}
	args[0] = 'del'
	for i := 0; i < keys.len; i++ {
		key := keys[i]
		args[1 + i] = key
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) expire(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, '')
}

pub fn (c CmdableFn) expire_nx(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'NX')
}

pub fn (c CmdableFn) expire_xx(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'XX')
}

pub fn (c CmdableFn) expire_gt(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'GT')
}

pub fn (c CmdableFn) expire_lt(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'LT')
}

fn (c CmdableFn) private_expire(key string, expiration time.Duration, mode string) &BoolCmd {
	mut args := []Value{len: 3, init: Value('')}
	args[0] = 'expire'
	args[1] = key
	args[2] = format_sec(expiration)
	if mode != '' {
		args = arrays.concat(args, mode)
	}

	mut cmd := new_bool_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

