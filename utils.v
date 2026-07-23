module redict

// import context
import rand
import strings
import time

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

// exponential with jitter
fn retry_backoff(retry i32, min_backoff time.Duration, max_backoff time.Duration) time.Duration {
	if retry < 0 {
		panic('negative retry')
	}

	if min_backoff == 0 {
		return min_backoff
	}

	mut backoff := min_backoff << u32(retry)
	if backoff < min_backoff {
		return max_backoff
	}

	jitter := rand.i64n(i64(backoff)) or { panic(err) } // panics when negative
	backoff = min_backoff + time.Duration(jitter)

	if backoff > max_backoff || backoff < min_backoff {
		backoff = max_backoff
	}

	return backoff
}

// TODO https://github.com/vlang/v/issues/27914
// fn sleep(mut ctx context.Context, d time.Duration) ! {
// 	timer := time.new_timer(d)
// 	defer { timer.stop() }
// 	done := ctx.done() // https://github.com/vlang/v/issues/15268

// 	select {
// 		_ := <-timer.c {
// 			return
// 		}
// 		_ := <-done {
// 			return ctx.err()
// 		}
// 	}
// }

fn v_or[T](o ?T, default T) T {
	v := o or { return default }
	return v
}
