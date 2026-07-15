module redict

import time
import strings

const keep_ttl = -1

pub const lib = 'redict'

pub interface Value {}

struct Empty {}

pub struct RedictError {
	msg    string
	is_nil bool
}

pub fn (re RedictError) msg() string {
	return re.msg
}

pub fn (re RedictError) code() int {
	return 0 // not using codes. Implements IError
}

pub fn (re RedictError) is_nil() bool {
	return re.is_nil
}

fn format_error_message(message string) string {
	return '${redict_error_prefix} ${message}'
}

fn new_redict_error(msg string) RedictError {
	return RedictError{
		msg: format_error_message(msg)
	}
}

fn new_nil() RedictError {
	return RedictError{
		msg:    format_error_message('nil')
		is_nil: true
	}
}

const redict_error_prefix = '[${lib}]:'

pub const redict_nil = new_nil()

pub fn is_error(err IError) bool {
	return err.msg().starts_with(redict_error_prefix)
}

pub fn is_nil(err IError) bool {
	match err {
		RedictError {
			return err.is_nil()
		}
		else {
			return false
		}
	}
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

fn replace_spaces(s string) string {
	mut res := strings.new_builder(s.len)
	for _, c in s {
		match c {
			` ` {
				res.write_rune(`-`)
			}
			else {
				res.write_rune(c)
			}
		}
	}
	return res.str()
}
