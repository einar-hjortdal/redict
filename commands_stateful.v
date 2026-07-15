module redict

import arrays
import v.util.version

pub struct LibInfo {
pub:
	name    ?string
	version ?string
}

interface StatefulCmdable {
	Cmdable
	auth_acl(username string, password string) &StatusCmd
	auth(password string) &StatusCmd
	client_set_name(name string) &BoolCmd
	client_set_info(info LibInfo) &StatusCmd
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

pub fn (c StatefulCmdableFn) client_set_info(libinfo LibInfo) &StatusCmd {
	if libinfo.name != none && libinfo.version != none {
		panic('both name and version cannot be set at the same time')
	}

	if libinfo.name == none && libinfo.version == none {
		panic('at least one of name and version should be set')
	}

	mut cmd := &StatusCmd{}
	if name := libinfo.name {
		libname := 'einar-hjortdal/redict(${name},${replace_spaces(version.full_v_version(false))})'
		cmd = new_status_cmd('client', 'setinfo', 'LIB-NAME', libname)
	} else {
		cmd = new_status_cmd('client', 'setinfo', 'LIB-VER', libinfo.version)
	}
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
