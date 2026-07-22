module redict

import time

pub struct LPosArgs {
pub:
	rank   ?i64
	maxlen ?i64
}

pub interface ListCmdable {
	blmove(source string, destination string, srcpos string, destpos string, timeout time.Duration) &StringCmd
	blmpop(timeout time.Duration, direction string, count i64, keys ...string) &KeyValuesCmd
	blpop(timeout time.Duration, keys ...string) &StringSliceCmd
	brpop(timeout time.Duration, keys ...string) &StringSliceCmd
	brpoplpush(source string, destination string, timeout time.Duration) &StringCmd
	lindex(key string, index i64) &StringCmd
	linsert(key string, position string, pivot Value, value Value) &IntCmd
	llen(key string) &IntCmd
	lmove(source string, destination string, srcpos string, destpos string) &StringCmd
	lmpop(direction string, count i64, keys ...string) &KeyValuesCmd
	lpop(key string) &StringCmd
	lpop_count(key string, count i64) &StringSliceCmd
	lpos(key string, value string, args LPosArgs) &IntCmd
	lpos_count(key string, value string, count i64, args LPosArgs) &IntSliceCmd
	lpush(key string, values ...Value) &IntCmd
	lpushx(key string, values ...Value) &IntCmd
	lrange(key string, start i64, stop i64) &StringSliceCmd
	lrem(key string, count i64, value Value) &IntCmd
	lset(key string, index i64, value Value) &StatusCmd
	ltrim(key string, start i64, stop i64) &StatusCmd
	rpop(key string) &StringCmd
	rpop_count(key string, count i64) &StringSliceCmd
	rpoplpush(source string, destination string) &StringCmd
	rpush(key string, values ...Value) &IntCmd
	rpushx(key string, values ...Value) &IntCmd
}

pub fn (c CmdableFn) blmove(
	source string,
	destination string,
	srcpos string,
	destpos string,
	timeout time.Duration) &StringCmd {
	mut cmd := new_string_cmd('BLMOVE', source, destination, srcpos, destpos, format_sec(timeout))
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) blmpop(timeout time.Duration, direction string, count i64, keys ...string) &KeyValuesCmd {
	mut args := []Value{len: 0, cap: keys.len + 6, init: Empty{}}
	args << 'BLMPOP'
	args << format_sec(timeout)
	args << keys.len
	args << keys
	args << direction
	args << 'COUNT'
	args << count

	mut cmd := new_key_values_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) blpop(timeout time.Duration, keys ...string) &StringSliceCmd {
	mut args := []Value{len: 0, cap: keys.len + 2, init: Empty{}}
	args << 'BLPOP'
	args << keys
	args << format_sec(timeout)

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) brpop(timeout time.Duration, keys ...string) &StringSliceCmd {
	mut args := []Value{len: 0, cap: keys.len + 2, init: Empty{}}
	args << 'BRPOP'
	args << keys
	args << format_sec(timeout)

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) brpoplpush(source string, destination string, timeout time.Duration) &StringCmd {
	mut cmd := new_string_cmd('BRPOPLPUSH', source, destination, format_sec(timeout))
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lindex(key string, index i64) &StringCmd {
	mut cmd := new_string_cmd('LINDEX', key, index)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) linsert(key string, position string, pivot Value, value Value) &IntCmd {
	mut cmd := new_int_cmd('LINSERT', key, position, pivot, value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) llen(key string) &IntCmd {
	mut cmd := new_int_cmd('LLEN', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lmove(source string, destination string, srcpos string, destpos string) &StringCmd {
	mut cmd := new_string_cmd('LMOVE', source, destination, srcpos, destpos)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lmpop(direction string, count i64, keys ...string) &KeyValuesCmd {
	mut args := []Value{len: 0, cap: keys.len + 5, init: Empty{}}
	args << 'LMPOP'
	args << keys.len
	args << keys
	args << direction
	args << 'COUNT'
	args << count

	mut cmd := new_key_values_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lpop(key string) &StringCmd {
	mut cmd := new_string_cmd('LPOP', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lpop_count(key string, count i64) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('LPOP', key, count)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lpos(key string, value string, lpos_args LPosArgs) &IntCmd {
	mut args := []Value{len: 0, cap: 6, init: Empty{}}
	args << key
	args << value

	if rank := lpos_args.rank {
		args << 'RANK'
		args << rank
	}

	if maxlen := lpos_args.maxlen {
		args << 'MAXLEN'
		args << maxlen
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lpos_count(key string, value string, count i64, lpos_args LPosArgs) &IntSliceCmd {
	mut args := []Value{len: 0, cap: 8, init: Empty{}}
	args << key
	args << value
	args << 'COUNT'
	args << count

	if rank := lpos_args.rank {
		args << 'RANK'
		args << rank
	}

	if maxlen := lpos_args.maxlen {
		args << 'MAXLEN'
		args << maxlen
	}

	mut cmd := new_int_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lpush(key string, values ...Value) &IntCmd {
	mut args := []Value{len: 0, cap: values.len + 2, init: Empty{}}
	args << 'LPUSH'
	args << key
	args << values

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lpushx(key string, values ...Value) &IntCmd {
	mut args := []Value{len: 0, cap: values.len + 2, init: Empty{}}
	args << 'LPUSHX'
	args << key
	args << values

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lrange(key string, start i64, stop i64) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('LRANGE', key, start, stop)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lrem(key string, count i64, value Value) &IntCmd {
	mut cmd := new_int_cmd('LREM', key, count, value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) lset(key string, index i64, value Value) &StatusCmd {
	mut cmd := new_status_cmd('LSET', key, index, value)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) ltrim(key string, start i64, stop i64) &StatusCmd {
	mut cmd := new_status_cmd('LTRIM', key, start, stop)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) rpop(key string) &StringCmd {
	mut cmd := new_string_cmd('RPOP', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) rpop_count(key string, count i64) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('RPOP', key, count)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) rpoplpush(source string, destination string) &StringCmd {
	mut cmd := new_string_cmd('RPOPLPUSH', source, destination)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) rpush(key string, values ...Value) &IntCmd {
	mut args := []Value{len: 0, cap: values.len + 2, init: Empty{}}
	args << 'RPUSH'
	args << key
	args << values

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) rpushx(key string, values ...Value) &IntCmd {
	mut args := []Value{len: 0, cap: values.len + 2, init: Empty{}}
	args << 'RPUSHX'
	args << key
	args << values

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}
