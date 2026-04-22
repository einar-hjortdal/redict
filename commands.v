module redict

interface Cmdable {
	GenericCmdable
	HashCmdable
	SetCmdable
	StringCmdable
	ping() &StatusCmd
}

type CmdableFn = fn (cmd &Cmder) !

// to get around @[required]
fn placeholder_cmdable_fn(cmd &Cmder) ! {
	return error('placeholder CmdableFn was called')
}

pub fn (c CmdableFn) ping() &StatusCmd {
	cmd := new_status_cmd('ping')
	c(cmd) or {}
	return cmd
}

