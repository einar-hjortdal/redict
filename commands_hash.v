module redict

// https://redict.io/docs/commands/#hash
interface HashCmdable {
	hdel(key string, fields ...string) &IntCmd
	hget(key string, index string) &StringCmd
	hset(key string, values []Value) &IntCmd
}

pub fn (c CmdableFn) hdel(key string, fields ...string) &IntCmd {
	mut args := []Value{len: 2 + fields.len, init: Value('')}
	args[0] = 'hdel'
	args[1] = key
	for i := 0; i < fields.len; i++ {
		field := fields[i]
		args[2 + i] = field
	}

	cmd := new_int_cmd(...args)
	c(cmd) or {}
	return cmd
}

pub fn (c CmdableFn) hget(key string, index string) &StringCmd {
	cmd := new_string_cmd('hget', key, index)
	c(cmd) or {}
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

	cmd := new_int_cmd(...args)
	c(cmd) or {}
	return cmd
}

