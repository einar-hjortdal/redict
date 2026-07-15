module redict

// https://redict.io/docs/commands/#hash
interface HashCmdable {
	hdel(key string, fields ...string) &IntCmd
	hexists(key string, field string) &BoolCmd
	hget(key string, index string) &StringCmd
	hgetall(key string) &MapStringStringCmd
	hincrby(key string, field string, incr i64) &IntCmd
	hincrbyfloat(key string, field string, incr f64) &FloatCmd
	hkeys(key string) &StringSliceCmd
	hlen(key string) &IntCmd
	// hmget(key string, fields ...string) &SliceCmd
	hmset(key string, values ...Value) &BoolCmd
	hrandfield(key string, count int) &StringSliceCmd
	// hrandfield_with_values(key string, count int) &KeyValueSliceCmd
	// hscan(key string, cursor u64, match string, count i64) &ScanCmd
	hset(key string, values []Value) &IntCmd
	hsetnx(key string, field string, value Value) &BoolCmd
	// hstrlen(key string, field string) &IntCmd
	hvals(key string) &StringSliceCmd
}

pub fn (c CmdableFn) hdel(key string, fields ...string) &IntCmd {
	mut args := []Value{len: 2 + fields.len, init: Value('')}
	args[0] = 'hdel'
	args[1] = key
	for i := 0; i < fields.len; i++ {
		field := fields[i]
		args[2 + i] = field
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hexists(key string, field string) &BoolCmd {
	mut cmd := new_bool_cmd('hexists', key, field)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hget(key string, index string) &StringCmd {
	mut cmd := new_string_cmd('hget', key, index)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hgetall(key string) &MapStringStringCmd {
	mut cmd := new_map_string_string_cmd('hgetall', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hincrby(key string, field string, incr i64) &IntCmd {
	mut cmd := new_int_cmd('hincrby', key, field, incr)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hincrbyfloat(key string, field string, incr f64) &FloatCmd {
	mut cmd := new_float_cmd('hincrby', key, field, incr)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hkeys(key string) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('hkeys', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hlen(key string) &IntCmd {
	mut cmd := new_int_cmd('hlen', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hmset(key string, values ...Value) &BoolCmd {
	mut args := []Value{len: 0, cap: values.len + 2, init: Value(Empty{})}
	args << 'hmset'
	args << key
	args << values

	mut cmd := new_bool_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hrandfield(key string, count int) &StringSliceCmd {
	mut cmd := new_string_slice_cmd('hrandfield', key, count)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hset(key string, values ...Value) &IntCmd {
	mut args := []Value{len: 2 + values.len, init: Value('')}
	args[0] = 'hset'
	args[1] = key
	for i := 0; i < values.len; i++ {
		value := values[i]
		args[2 + i] = value
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hsetnx(key string, field string, value Value) &BoolCmd {
	mut cmd := new_bool_cmd('hsetnx', key, field, value)
	c(mut cmd) or {}
	return cmd
}
