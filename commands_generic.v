module redict

import time

// https://redict.io/docs/commands/#generic
pub interface GenericCmdable {
	del(keys ...string) &IntCmd
	dump(key string) &StringCmd
	exists(keys ...string) &IntCmd
	expire(key string, expiration time.Duration) &BoolCmd
	expireat(key string, t time.Time) &BoolCmd
	expiregt(key string, expiration time.Duration) &BoolCmd
	expirelt(key string, expiration time.Duration) &BoolCmd
	expirenx(key string, expiration time.Duration) &BoolCmd
	expirexx(key string, expiration time.Duration) &BoolCmd
	expiretime(key string) &DurationCmd
	keys(pattern string) &StringSliceCmd
	// migrate
	// move
	// objectfreq
	// objectrefcount
	// objectencoding
	// objectidletime
	persist(key string) &BoolCmd
	pexpire(key string, expiration time.Duration) &BoolCmd
	pexpireat(key string, t time.Time) &BoolCmd
	pexpiretime(key string) &DurationCmd
	pttl(key string) &DurationCmd
	randomkey() &StringCmd
	rename(key string, newkey string) &StatusCmd
	renamenx(key string, newkey string) &BoolCmd
	restore(key string, ttl time.Duration, value string) &BoolCmd
	restorereplace(key string, ttl time.Duration, value string) &StatusCmd
	// sort
	// sortro
	// sortstore
	// sortinterfaces
	touch(keys ...string) &IntCmd
	ttl(key string) &DurationCmd
	type(key string) &StatusCmd
	copy(sourceKey string, destKey string, db int, replace bool) &IntCmd
	copyreplace(sourceKey string, destKey string, db int, replace bool) &IntCmd
	// scan
	// scantype
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

pub fn (c CmdableFn) dump(key string) &StringCmd {
	mut cmd := new_string_cmd('dump', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) exists(keys ...string) &IntCmd {
	mut args := []Value{len: 1 + keys.len, init: Value('')}
	args[0] = 'exists'
	for i := 0; i < keys.len; i++ {
		key := keys[i]
		args[1 + i] = key
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

fn (c CmdableFn) private_expire(key string, expiration time.Duration, mode string) &BoolCmd {
	mut args := []Value{len: 0, cap: 4, init: Value(Empty{})}
	args << 'expire'
	args << key
	args << format_sec(expiration)
	if mode != '' {
		args << mode
	}

	mut cmd := new_bool_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) expire(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, '')
}

pub fn (c CmdableFn) expirenx(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'NX')
}

pub fn (c CmdableFn) expirexx(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'XX')
}

pub fn (c CmdableFn) expiregt(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'GT')
}

pub fn (c CmdableFn) expirelt(key string, expiration time.Duration) &BoolCmd {
	return c.private_expire(key, expiration, 'LT')
}

pub fn (c CmdableFn) expireat(key string, t time.Time) &BoolCmd {
	mut cmd := new_bool_cmd('expireat', key, t.unix())
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) expiretime(key string) &DurationCmd {
	mut cmd := new_duration_cmd(time.second, 'expiretime', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) keys(pattern string) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('keys', pattern)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) persist(key string) &BoolCmd {
	mut cmd := new_bool_cmd('persist', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) pexpire(key string, expiration time.Duration) &BoolCmd {
	mut cmd := new_bool_cmd('pexpire', key, format_ms(expiration))
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) pexpireat(key string, t time.Time) &BoolCmd {
	mut cmd := new_bool_cmd('pexpireat', key, t.unix_nano() / time.millisecond)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) pexpiretime(key string) &DurationCmd {
	mut cmd := new_duration_cmd(time.millisecond, 'pexpiretime', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) pttl(key string) &DurationCmd {
	mut cmd := new_duration_cmd(time.millisecond, 'pttl', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) randomkey() &StringCmd {
	mut cmd := new_string_cmd('randomkey')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) rename(key string, newkey string) &StatusCmd {
	mut cmd := new_status_cmd('rename', key, newkey)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) renamenx(key string, newkey string) &BoolCmd {
	mut cmd := new_bool_cmd('renamenx', key, newkey)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) restore(key string, ttl time.Duration, value string) &BoolCmd {
	mut cmd := new_bool_cmd('restore', key, format_ms(ttl), value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) restorereplace(key string, ttl time.Duration, value string) &StatusCmd {
	mut cmd := new_status_cmd('restore', key, format_ms(ttl), value, 'replace')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) touch(keys ...string) &IntCmd {
	mut args := []Value{len: 0, cap: keys.len + 1, init: Value(Empty{})}
	args << 'touch'
	args << keys

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) ttl(key string) &DurationCmd {
	mut cmd := new_duration_cmd(time.millisecond, 'ttl', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) type(key string) &StatusCmd {
	mut cmd := new_status_cmd('type', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) copy(sourceKey string, destKey string, db int) &IntCmd {
	mut cmd := new_int_cmd('copy', sourceKey, destKey, 'DB', db)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) copyreplace(sourceKey string, destKey string, db int) &IntCmd {
	mut cmd := new_int_cmd('copy', sourceKey, destKey, 'DB', db, 'REPLACE')
	c(mut cmd) or {}
	return cmd
}
