module redict

import arrays

pub interface SetCmdable {
	sadd(key string, members ...Value) &IntCmd
	scard(key string) &IntCmd
	sdiff(keys ...string) &StringSliceCmd
	sdiffstore(destination string, keys ...string) &IntCmd
	sinter(keys ...string) &StringSliceCmd
	sintercard(limit i64, keys ...string) &IntCmd
	sinterstore(destination string, keys ...string) &IntCmd
	sismember(key string, member Value) &BoolCmd
	smembers(key string) &StringSliceCmd
	smismember(key string, members ...Value) &BoolSliceCmd
	smove(source string, destination string, member Value) &BoolCmd
	spop(key string) &StringCmd
	spopn(key string, count i64) &StringSliceCmd
	srandmember(key string) &StringCmd
	srandmembern(key string, count i64) &StringSliceCmd
	srem(key string, members ...Value) &IntCmd
	// sscan(key string, cursor u64, match string, count i64) &ScanCmd
	sunion(keys ...string) &StringSliceCmd
	sunionstore(destination string, keys ...string) &IntCmd
}

pub fn (c CmdableFn) sadd(key string, members ...Value) &IntCmd {
	mut args := []Value{len: 0, cap: members.len + 2, init: Value(Empty{})}
	args << 'sadd'
	args << key
	args << members

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) scard(key string) &IntCmd {
	mut cmd := new_int_cmd('scard', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) sdiff(keys ...string) &StringSliceCmd {
	mut args := []Value{len: 0, cap: keys.len + 1, init: Value(Empty{})}
	args << 'sdiff'
	args << keys

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) sdiffstore(destination string, keys ...string) &IntCmd {
	mut args := []Value{len: 0, cap: keys.len + 2, init: Value(Empty{})}
	args << 'sdiffstore'
	args << destination
	args << keys

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) sinter(keys ...string) &StringSliceCmd {
	mut args := []Value{len: 0, cap: keys.len + 1, init: Value(Empty{})}
	args << 'sinter'
	args << keys

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) sintercard(limit i64, keys ...string) &IntCmd {
	mut args := []Value{len: 0, cap: keys.len + 4, init: Value(Empty{})}
	args << 'sintercard'
	args << keys.len
	args << keys
	args << 'limit'
	args << limit

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) sinterstore(destination string, keys ...string) &IntCmd {
	mut args := []Value{len: 0, cap: keys.len + 2, init: Value(Empty{})}
	args << 'sinterstore'
	args << destination
	args << keys

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

pub fn (c CmdableFn) smismember(key string, members ...Value) &BoolSliceCmd {
	mut args := []Value{len: 0, cap: members.len + 2, init: Value(Empty{})}
	args << 'smismember'
	args << key
	args << members

	mut cmd := new_bool_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) smove(source string, destination string, member Value) &BoolCmd {
	mut cmd := new_bool_cmd('smove', source, destination, member)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) spop(key string) &StringCmd {
	mut cmd := new_string_cmd('spop', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) spopn(key string, count i64) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('spop', key, count)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) srandmember(key string) &StringCmd {
	mut cmd := new_string_cmd('srandmember', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) srandmembern(key string, count i64) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('srandmember', key, count)
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

pub fn (c CmdableFn) sunion(keys ...string) &StringSliceCmd {
	mut args := []Value{len: 0, cap: keys.len + 1, init: Value(Empty{})}
	args << 'sunion'
	args << keys

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) sunionstore(destination string, keys ...string) &IntCmd {
	mut args := []Value{len: 0, cap: keys.len + 2, init: Value(Empty{})}
	args << 'sunionstore'
	args << destination
	args << keys

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}
