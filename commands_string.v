module redict

import arrays
import time

// https://redict.io/docs/commands/#string
interface StringCmdable {
	get(key string) &StringCmd
	set(key string, value Value, expiration time.Duration) &StatusCmd
}

pub fn (c CmdableFn) get(key string) &StringCmd {
	mut cmd := new_string_cmd('get', key)
	c(mut cmd) or {}
	return cmd
}

// set issues a `SET key value [expiration]` command.
// Zero expiration means the key has no expiration time.
pub fn (c CmdableFn) set(key string, value Value, expiration time.Duration) &StatusCmd {
	mut args := []Value{len: 3, init: Value('')}
	args[0] = 'set'
	args[1] = key
	args[2] = value
	if expiration > 0 {
		if use_precise(expiration) {
			args = arrays.concat(args, 'px', format_ms(expiration))
		} else {
			args = arrays.concat(args, 'ex', format_sec(expiration))
		}
	} else if expiration == keep_ttl {
		args = arrays.concat(args, 'keepttl')
	}

	mut cmd := new_status_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

