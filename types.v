module redict

pub interface Value {}

// Nil is the value the redict client returns when the server responds with the RESP Null Bulk String
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

// Returns the string contained in v, also returns true if v is Nil. Error if v is not a string.
pub fn (v Value) get_string() !(string, bool) {
	match v {
		string {
			return *v, false
		}
		Nil {
			return '', true
		}
		RedictError {
			return v
		}
		else {
			return error(format_error_message('Value is not string'))
		}
	}
}
