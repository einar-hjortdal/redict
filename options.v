module redict

import net
import net.urllib
import runtime

const protocol_flag_string = 'redict://'
const default_host_string = 'localhost'
const default_port_string = '6379'

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
}

struct ParsedOptions {
	address              string
	username             string
	password             string
	db                   int
	dialer               fn (addr string) !&net.TcpConn = unsafe { nil }
	url                  string
	pool_size            int
	min_idle_connections int
	max_idle_connections int
	max_retries          int
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
	unsafe {
		if url.user != nil {
			username = url.user.username
			password = url.user.password
		}
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
		dialer:               new_dialer(address)
		pool_size:            pool_size
		min_idle_connections: opts.min_idle_connections
		max_idle_connections: opts.max_idle_connections
		max_retries:          max_retries
	}
}

fn new_dialer(address string) fn (address string) !&net.TcpConn {
	return fn [address] (addr string) !&net.TcpConn {
		return net.dial_tcp('${addr}')!
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
