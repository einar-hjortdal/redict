module redict

import context
import net
import time

struct BaseClient {
	options ParsedOptions
mut:
	connection_pool &Pooler
	on_close        ?fn () !
}

fn (mut c BaseClient) new_connection() !&PoolConnection {
	mut cn := c.connection_pool.new_connection()!

	c.init_connection(mut cn) or {
		c.connection_pool.close_connection(mut cn)!
		return err
	}

	return cn
}

fn (mut c BaseClient) get_connection() !&PoolConnection {
	return c.retrieve_connection()!
}

fn (mut c BaseClient) retrieve_connection() !&PoolConnection {
	mut cn := c.connection_pool.get()!
	if cn.initialized {
		return cn
	}

	c.init_connection(mut cn) or {
		c.connection_pool.remove(mut cn, err.msg())
		return err
	}

	return cn
}

fn (mut c BaseClient) init_connection(mut cn PoolConnection) ! {
	if cn.initialized {
		return
	}
	cn.initialized = true

	mut cp := new_single_connection_pool(mut c.connection_pool, mut cn)
	mut conn := new_connection(c.options, mut cp)

	conn.hello(3, c.options.username, c.options.password, 'einar_hjortdal.redict')

	if c.options.db > 0 {
		conn.select_db(c.options.db)
	}
}

fn (mut c BaseClient) release_connection(mut cn PoolConnection) ! {
	c.connection_pool.put(mut cn)!
}

fn (mut c BaseClient) with_connection(f fn (mut PoolConnection) !) ! {
	mut cn := c.get_connection()!
	f(mut cn) or {
		c.release_connection(mut cn)!
		return err
	}
	c.release_connection(mut cn)!
}

fn (mut c BaseClient) dial(address string) !&net.TcpConn {
	return c.options.dialer(address)
}

fn (mut c BaseClient) retry_backoff(attempt int) time.Duration {
	return retry_backoff(attempt, c.options.min_retry_backoff, c.options.max_retry_backoff)
}

fn (mut c BaseClient) cmd_timeout(cmd &Cmder) time.Duration {
	if timeout := cmd.read_timeout() {
		if timeout == 0 {
			return 0
		}
		return timeout + 10 * time.second
	}
	return c.options.read_timeout
}

fn (mut c BaseClient) attempt_process(mut cmd Cmder) ! {
	c.with_connection(fn [mut c, mut cmd] (mut pc PoolConnection) ! {
		pc.with_writer(c.options.write_timeout, fn [cmd] (mut wr ProtoWriter) ! {
			write_cmd(mut wr, cmd)!
		})!
		pc.with_reader(c.cmd_timeout(cmd), cmd.read_reply)! // TODO needs atomic or something
	})!
}

fn (mut c BaseClient) process(mut cmd Cmder) ! {
	mut last_error := ?IError(none)
	for attempt := 0; attempt <= c.options.max_retries; attempt++ {
		if attempt > 0 {
			mut ctx := context.todo()
			sleep(mut ctx, c.retry_backoff(attempt))!
		}

		c.attempt_process(mut cmd) or {
			if attempt == c.options.max_retries {
				return err
			} else {
				last_error = err
				continue
			}
		}
		break
	}

	if err := last_error {
		return err
	}
}

// close closes the client, releasing any open resources.
// It is rare to close a Client, as the Client is meant to be long-lived and shared between many coroutines.
fn (mut c BaseClient) close() ! {
	c.connection_pool.close()!
}

// Client representing a pool of zero or more underlying connections. A client creates and frees connections
// automatically.
@[heap]
pub struct Client {
	BaseClient
	CmdableFn
}

// new_client returns a client according to the specified Options.
pub fn new_client(options Options) !&Client {
	o := options.init()!

	mut c := &Client{
		options:         o
		connection_pool: private_new_connection_pool(o)
	}
	c.CmdableFn = c.process
	return c
}

fn (mut c Client) process(mut cmd Cmder) ! {
	c.BaseClient.process(mut cmd) or {
		cmd.set_error(err)
		return err
	}
}

pub fn (mut c Client) do(args ...Value) &Cmd {
	mut cmd := new_cmd(...args)
	c.process(mut cmd) or {}
	return cmd
}

// Connection represents a single connection rather than a pool of connections. A Connection is used
// to start a new client and should not be used unless strictly necessary.
@[heap]
pub struct Connection {
	BaseClient
	CmdableFn
	StatefulCmdableFn
}

fn new_connection(po ParsedOptions, mut cp Pooler) &Connection {
	mut c := &Connection{
		options:         po
		connection_pool: cp
	}
	c.CmdableFn = c.process
	c.StatefulCmdableFn = c.process
	return c
}

fn (mut c Connection) process(mut cmd Cmder) ! {
	c.BaseClient.process(mut cmd) or {
		cmd.set_error(err)
		return err
	}
}
