module redict

import arrays
import time

fn use_precise(duration time.Duration) bool {
	return duration < time.second || duration % time.second != 0
}

fn format_ms(duration time.Duration) i64 {
	if duration > 0 && duration < time.millisecond {
		return 1
	}
	return i64(duration / time.millisecond)
}

fn format_sec(duration time.Duration) i64 {
	if duration > 0 && duration < time.second {
		return 1
	}
	return i64(duration / time.second)
}

struct Cmdable {
mut:
	cmdable_function fn (cmd &Cmder) ! = unsafe { nil }
}

pub fn (c Cmdable) ping() !&StatusCmd {
	cmd := new_status_cmd('ping')
	c.cmdable_function(cmd)!
	return cmd
}

pub fn (c Cmdable) del(keys ...string) !&IntCmd {
	mut args := []Value{}
	args << 'del'
	for key in keys {
		args = arrays.concat(args, key)
	}
	cmd := new_int_cmd(...args)
	c.cmdable_function(cmd)!
	return cmd
}

pub fn (c Cmdable) expire(key string, expiration time.Duration) !&BoolCmd {
	return c.private_expire(key, expiration, '')
}

pub fn (c Cmdable) expire_nx(key string, expiration time.Duration) !&BoolCmd {
	return c.private_expire(key, expiration, 'NX')
}

pub fn (c Cmdable) expire_xx(key string, expiration time.Duration) !&BoolCmd {
	return c.private_expire(key, expiration, 'XX')
}

pub fn (c Cmdable) expire_gt(key string, expiration time.Duration) !&BoolCmd {
	return c.private_expire(key, expiration, 'GT')
}

pub fn (c Cmdable) expire_lt(key string, expiration time.Duration) !&BoolCmd {
	return c.private_expire(key, expiration, 'LT')
}

fn (c Cmdable) private_expire(key string, expiration time.Duration, mode string) !&BoolCmd {
	mut args := []Value{}
	args << 'expire'
	args << key
	args << format_sec(expiration)
	if mode != '' {
		args << mode
	}
	cmd := new_bool_cmd(...args)
	c.cmdable_function(cmd)!
	return cmd
}

pub fn (c Cmdable) get(key string) !&StringCmd {
	cmd := new_string_cmd('get', key)
	c.cmdable_function(cmd)!
	return cmd
}

// set issues a `SET key value [expiration]` command.
// Zero expiration means the key has no expiration time.
pub fn (c Cmdable) set(key string, value string, expiration time.Duration) !&StatusCmd {
	mut args := []Value{}
	args << 'set'
	args << key
	args << value
	if expiration > 0 {
		if use_precise(expiration) {
			args = arrays.concat(args, 'px', format_ms(expiration))
		} else {
			args = arrays.concat(args, 'ex', format_sec(expiration))
		}
	}
	cmd := new_status_cmd(...args)
	c.cmdable_function(cmd)!
	return cmd
}

pub fn (c Cmdable) hset(key string, values []Value) !&IntCmd {
	mut args := []Value{}
	args << 'hset'
	args << key
	args << values
	cmd := new_int_cmd(...args)
	c.cmdable_function(cmd)!
	return cmd
}

pub fn (c Cmdable) hget(key string, index string) !&StringCmd {
	cmd := new_string_cmd('hget', key, index)
	c.cmdable_function(cmd)!
	return cmd
}

struct CmdableStateful {
mut:
	cmdable_stateful_function fn (mut cmd Cmder) ! = unsafe { nil }
}

pub fn (c CmdableStateful) auth(password string) !&StatusCmd {
	mut cmd := new_status_cmd('auth', password)
	c.cmdable_stateful_function(mut cmd)!
	return cmd
}

pub fn (c CmdableStateful) auth_acl(username string, password string) !&StatusCmd {
	mut cmd := new_status_cmd('auth', username, password)
	c.cmdable_stateful_function(mut cmd)!
	return cmd
}

pub fn (c CmdableStateful) hello(protover int, username string, password string, client_name string) !&MapStringValueCmd {
	mut args := []Value{}
	args = arrays.concat(args, 'hello', protover)
	if password != '' {
		if username != '' {
			args = arrays.concat(args, 'auth', username, password)
		} else {
			args = arrays.concat(args, 'auth', 'default', password)
		}
	}
	if client_name != '' {
		args = arrays.concat(args, 'setname', client_name)
	}
	mut cmd := new_map_string_value_cmd(...args)

	c.cmdable_stateful_function(mut cmd)!
	return cmd
}

// It is called `select_db` because `select` is a reserved keyword.
pub fn (c CmdableStateful) select_db(index int) !&StatusCmd {
	mut cmd := new_status_cmd('select', index)
	c.cmdable_stateful_function(mut cmd)!
	return cmd
}
