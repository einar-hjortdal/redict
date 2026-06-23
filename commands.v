module redict

interface Cmdable {
	GenericCmdable
	HashCmdable
	SetCmdable
	StringCmdable
	ping() &StatusCmd
}

type CmdableFn = fn (mut cmd Cmder) !

pub fn (c CmdableFn) ping() &StatusCmd {
	mut cmd := new_status_cmd('ping')
	c(mut cmd) or {}
	return cmd
}
