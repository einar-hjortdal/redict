module redis

import runtime
import net
import pool

pub struct Options {
mut:
	// dialer is set with the `init` method.
	dialer fn (addr string) !&net.TcpConn = unsafe { nil }
pub mut:
	// address is expected in a host:port form, defaults to 'localhost:6379'
	address string
	// username is optional.
	username string
	// password is optional.
	password string
	// db defaults to 0.
	db int
	// pool_size defaults to 10 connections per CPU thread.
	// it represents the maximim number of connections in the pool.
	pool_size int
	// mind_idle_connections defaults to 0.
	min_idle_connections int
	// max_idle_connections defaults to 0, idle connections will not be closed.
	max_idle_connections int
	// max_retries is the maximum number of retries before giving up.
	// Defaults to 3, 0 is set to 3. -1 disables retries.
	max_retries int
}

fn (mut opts Options) init() {
	if opts.address == '' {
		opts.address = 'localhost:6379'
	}
	if opts.pool_size == 0 {
		opts.pool_size = 10 * runtime.nr_cpus()
	}
	if opts.max_retries == 0 {
		opts.max_retries = 3
	}
	opts.dialer = new_dialer(opts)
}

fn new_dialer(opts Options) fn (address string) !&net.TcpConn {
	return fn [opts] (address string) !&net.TcpConn {
		return net.dial_tcp('${opts.address}')!
	}
}

fn new_connection_pool(opts Options) &pool.ConnectionPool {
	pool_opts := &pool.Options{
		dialer: fn [opts] () !&net.TcpConn {
			return opts.dialer(opts.address)
		}
		pool_size: opts.pool_size
	}
	return pool.new_connection_pool(pool_opts)
}
