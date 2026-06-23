module redict

import arrays

interface StatefulCmdable {
	Cmdable
	auth_acl(username string, password string) &StatusCmd
	auth(password string) &StatusCmd
	client_set_name(name string) &BoolCmd
	hello(protover int, username string, password string, client_name string) &MapStringValueCmd
	select_db(index int) &StatusCmd
	swap_db(index1 int, index2 int) &StatusCmd
}

type StatefulCmdableFn = fn (mut cmd Cmder) !

pub fn (c StatefulCmdableFn) auth(password string) &StatusCmd {
	mut cmd := new_status_cmd('auth', password)
	c(mut cmd) or {}
	return cmd
}

pub fn (c StatefulCmdableFn) auth_acl(username string, password string) &StatusCmd {
	mut cmd := new_status_cmd('auth', username, password)
	c(mut cmd) or {}
	return cmd
}

pub fn (c StatefulCmdableFn) client_set_name(name string) &BoolCmd {
	mut cmd := new_bool_cmd('client', 'setname', name)
	c(mut cmd) or {}
	return cmd
}

pub fn (c StatefulCmdableFn) hello(protover int, username string, password string, client_name string) &MapStringValueCmd {
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

	c(mut cmd) or {}
	return cmd
}

// It is called `select_db` because `select` is a reserved keyword.
pub fn (c StatefulCmdableFn) select_db(index int) &StatusCmd {
	mut cmd := new_status_cmd('select', index)
	c(mut cmd) or {}
	return cmd
}

pub fn (c StatefulCmdableFn) swap_db(index1 int, index2 int) &StatusCmd {
	mut cmd := new_status_cmd('swapdb', index1, index2)
	c(mut cmd) or {}
	return cmd
}
