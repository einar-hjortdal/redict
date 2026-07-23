module redict

import net
import net.urllib
import runtime
import time

pub const protocol_flag_string = 'redict://'
pub const default_host_string = 'localhost'
pub const default_port_string = '6379'
pub const default_min_retry_backoff = 8 * time.millisecond
pub const default_max_retry_backoff = 512 * time.millisecond
pub const default_read_timeout = 3 * time.second
pub const default_write_timeout = 3 * time.second

pub struct Options {
pub:
	// [redict://]<user>:<pass>@<host>:<port>[/<db>]
	// Defaults to @localhost:6379/0
	url string
	// pool_size defaults to 10 connections per CPU thread.
	// it represents the maximum number of connections in the pool.
	pool_size int
	// mind_idle_connections defaults to 0.
	min_idle_connections int
	// max_idle_connections defaults to 0, idle connections will not be closed.
	max_idle_connections int
	// max_retries is the maximum number of retries before giving up.
	// Defaults to 3, 0 is set to 3. -1 disables retries.
	max_retries int
	// min_retry_backoff is the minimum backoff between each retry.
	// Defaults to 8 milliseconds
	min_retry_backoff ?time.Duration
	// max_retry_backoff is the maximum backoff between each retry.
	// Default to 512 milliseconds
	max_retry_backoff ?time.Duration
	// read_timeout is the timeout for reads. If reached, commands will fail with a timeout instead of blocking.
	// Defaults to 3 seconds.
	// `0` means no timeout (block indefinitely).
	read_timeout ?time.Duration
	// write_timeout is the timeout writes. If reached, commands will fail with a timeout instead of blocking.
	// Defaults to 3 seconds.
	// `0` means no timeout (block indefinitely).
	write_timeout ?time.Duration
}

struct ParsedOptions {
	address              string
	username             string
	password             string
	db                   int
	dialer               fn (addr string) !&net.TcpConn @[required]
	url                  string
	pool_size            int
	min_idle_connections int
	max_idle_connections int
	max_retries          int
	min_retry_backoff    time.Duration
	max_retry_backoff    time.Duration
	read_timeout         time.Duration
	write_timeout        time.Duration
}

fn parse_url(s string) !urllib.URL {
	if s.starts_with(protocol_flag_string) {
		return urllib.parse(s)!
	}
	return urllib.parse('${protocol_flag_string}${s}')!
}

fn get_address(s string) string {
	if s == '' {
		return '${default_host_string}:${default_port_string}'
	}

	if s.contains(':') {
		r := s.split(':')

		if r[0] == '' { // if no host, use default
			return '${default_host_string}:${r[1]}'
		}

		if r[1] == '' { // if no port, use default
			return '${r[0]}:${default_port_string}'
		}

		return s
	}

	// assume no port
	return '${s}:${default_port_string}'
}

fn (opts Options) init() !ParsedOptions {
	url := parse_url(opts.url)!
	address := get_address(url.host)
	mut username := ''
	mut password := ''
	if user := url.user {
		username = user.username
		password = user.password
	}
	db := url.path.trim('/').int()

	mut pool_size := 10 * runtime.nr_cpus()
	if opts.pool_size != 0 {
		pool_size = opts.pool_size
	}

	mut max_retries := 3
	if opts.max_retries != 0 {
		max_retries = opts.max_retries
	}

	return ParsedOptions{
		address:              address
		username:             username
		password:             password
		db:                   db
		dialer:               new_default_dialer()
		pool_size:            pool_size
		min_idle_connections: opts.min_idle_connections
		max_idle_connections: opts.max_idle_connections
		max_retries:          max_retries
		min_retry_backoff:    v_or(opts.min_retry_backoff, default_min_retry_backoff)
		max_retry_backoff:    v_or(opts.max_retry_backoff, default_max_retry_backoff)
		read_timeout:         v_or(opts.read_timeout, default_read_timeout)
		write_timeout:        v_or(opts.write_timeout, default_write_timeout)
	}
}

fn new_default_dialer() fn (string) !&net.TcpConn {
	return fn (s string) !&net.TcpConn {
		return net.dial_tcp(s)!
	}
}

fn private_new_connection_pool(opts ParsedOptions) &ConnectionPool {
	pool_opts := &PoolOptions{
		dialer:    fn [opts] () !&net.TcpConn {
			return opts.dialer(opts.address)
		}
		pool_size: opts.pool_size
	}
	return new_connection_pool(pool_opts)
}
