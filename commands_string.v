module redict

import time

// https://redict.io/docs/commands/#string
interface StringCmdable {
	append(key string, value string) &IntCmd
	decr(key string) &IntCmd
	decrby(key string, decrement i64) &IntCmd
	get(key string) &StringCmd
	getdel(key string) &StringCmd
	getex(key string, expiration time.Duration) &StringCmd
	getrange(key string, start i64, end i64) &StringCmd
	getset(key string, value Value) &StringCmd
	incr(key string) &IntCmd
	incrby(key string, value i64) &IntCmd
	// incrbyfloat(key string, value f64) &FloatCmd
	// lcs(q &LCSQuery) &LCSCmd
	// mget(keys ...string) &SliceCmd
	mset(values ...Value) &StatusCmd
	msetnx(values ...Value) &BoolCmd
	// psetex
	set(key string, value Value, expiration time.Duration) &StatusCmd
	setex(key string, value Value, expiration time.Duration) &StatusCmd
	setnx(key string, value Value, expiration time.Duration) &BoolCmd
	setrange(key string, offset i64, value string) &IntCmd
	strlen(key string) &IntCmd
	// substr
}

pub fn (c CmdableFn) append(key string, value string) &IntCmd {
	mut cmd := new_int_cmd('append', key, value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) decr(key string) &IntCmd {
	mut cmd := new_int_cmd('decr', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) decrby(key string, decrement i64) &IntCmd {
	mut cmd := new_int_cmd('decrby', key, decrement)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) get(key string) &StringCmd {
	mut cmd := new_string_cmd('get', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) getdel(key string) &StringCmd {
	mut cmd := new_string_cmd('getdel', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) getex(key string, expiration time.Duration) &StringCmd {
	mut args := []Value{len: 0, cap: 4, init: Empty{}}
	args << 'getex'
	args << key
	if expiration > 0 {
		if use_precise(expiration) {
			args << 'px'
			args << format_ms(expiration)
		} else {
			args << 'ex'
			args << format_sec(expiration)
		}
	} else if expiration == 0 {
		args << 'persist'
	}

	mut cmd := new_string_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) getrange(key string, start i64, end i64) &StringCmd {
	mut cmd := new_string_cmd('getrange', key, start, end)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) getset(key string, value Value) &StringCmd {
	mut cmd := new_string_cmd('getset', key, value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) incr(key string) &IntCmd {
	mut cmd := new_int_cmd('incr', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) incrby(key string, value i64) &IntCmd {
	mut cmd := new_int_cmd('incrby', key, value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) mset(key string, values ...Value) &StatusCmd {
	mut args := []Value{len: 0, cap: values.len + 1, init: Empty{}}
	args << 'mset'
	args << values
	mut cmd := new_status_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) msetnx(key string, values ...Value) &BoolCmd {
	mut args := []Value{len: 0, cap: values.len + 1, init: Empty{}}
	args << 'msetnx'
	args << values
	mut cmd := new_bool_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

// set issues a `SET key value [expiration]` command.
// Zero expiration means the key has no expiration time.
pub fn (c CmdableFn) set(key string, value Value, expiration time.Duration) &StatusCmd {
	mut args := []Value{len: 0, cap: 3, init: Empty{}}
	args << 'set'
	args << key
	args << value
	if expiration > 0 {
		if use_precise(expiration) {
			args << 'px'
			args << format_ms(expiration)
		} else {
			args << 'ex'
			args << format_sec(expiration)
		}
	} else if expiration == keep_ttl {
		args << 'keepttl'
	}

	mut cmd := new_status_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) setex(key string, value Value, expiration time.Duration) &StatusCmd {
	mut cmd := new_status_cmd('setex', key, format_sec(expiration))
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) setnx(key string, value Value, expiration time.Duration) &BoolCmd {
	mut cmd := &BoolCmd{}
	match expiration {
		0 {
			cmd = new_bool_cmd('setnx', key, value)
		}
		keep_ttl {
			cmd = new_bool_cmd('set', key, value, 'keepttl', 'nx')
		}
		else {
			if use_precise(expiration) {
				cmd = new_bool_cmd('set', key, value, 'px', format_ms(expiration), 'nx')
			} else {
				cmd = new_bool_cmd('set', key, value, format_sec(expiration), 'nx')
			}
		}
	}

	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) setrange(key string, offset i64, value string) &IntCmd {
	mut cmd := new_int_cmd('setrange', key, offset, value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) strlen(key string) &IntCmd {
	mut cmd := new_int_cmd('setrange', key)
	c(mut cmd) or {}
	return cmd
}
