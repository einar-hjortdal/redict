module redict

pub interface Value {}

pub struct Nil {}

pub struct RedictError {
	Error
	msg string
}

pub fn (re RedictError) msg() string {
	return re.msg
}

fn new_redict_error(err IError) RedictError {
	return RedictError{
		msg: err.msg()
	}
}
