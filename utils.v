module redict

import time

const keep_ttl = -1

pub const lib = 'redict'

pub interface Value {}

pub struct RedictError {
	msg string
}

pub fn (re RedictError) msg() string {
	return re.msg
}

pub fn (re RedictError) code() int {
	return 0 // not using codes. Implements IError
}

fn new_redict_error(msg string) RedictError {
	return RedictError{
		msg: msg
	}
}

const redict_error_prefix = '[${lib}]:'

fn format_error_message(message string) string {
	return '${redict_error_prefix} ${message}'
}

pub const redict_nil = new_redict_error(format_error_message('nil'))

pub fn is_error(err IError) bool {
	return err.msg().starts_with(redict_error_prefix)
}

pub fn is_nil(err IError) bool {
	return err.msg() == redict_nil.msg()
}

fn use_precise(duration time.Duration) bool {
	return duration < time.second || duration % time.second != 0
}

fn format_ms(duration time.Duration) i64 {
	if duration > 0 && duration < time.millisecond {
		return 1
	}
	return i64(duration / time.millisecond)
}

fn format_sec(duration time.Duration) i64 {
	if duration > 0 && duration < time.second {
		return 1
	}
	return i64(duration / time.second)
}

