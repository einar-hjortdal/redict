module pool

import arrays
import net
import sync
// import time

/*
*
 *
 * Pooler
 *
 *
*/

interface Pooler {
mut:
	new_connection() !&Connection
	close_connection(mut Connection) !
	get() !&Connection
	put(mut Connection) !
	remove(mut Connection, string)
	close() !
}

/*
*
 *
 * ConnectionPool
 *
 *
*/

pub struct Options {
	dialer               fn () !&net.TcpConn = unsafe { nil }
	pool_size            int
	min_idle_connections int
	max_idle_connections int
}

pub struct ConnectionPool {
	opts  Options
	queue chan int
mut:
	// connections contains the currently active connections.
	connections []&Connection
	// idle_connections contains the currently available connections.
	idle_connections []&Connection
	// idle_connections_length is the number of currently available connections.
	idle_connections_length int
	// pool_size is the current number of connections in the pool.
	pool_size int
	mutex     sync.Mutex
}

pub fn new_connection_pool(opts Options) &ConnectionPool {
	mut new := &ConnectionPool{
		opts: opts
		queue: chan int{cap: opts.pool_size}
		connections: []&Connection{}
		idle_connections: []&Connection{}
		mutex: sync.new_mutex()
	}

	new.mutex.@lock()
	new.check_min_idle_connections()
	new.mutex.unlock()

	return new
}

fn (mut pool ConnectionPool) check_min_idle_connections() {
	if pool.opts.min_idle_connections == 0 {
		return
	}
	for pool.pool_size < pool.opts.pool_size
		&& pool.idle_connections_length < pool.opts.min_idle_connections {
		if pool.queue.len < pool.queue.cap {
			pool.queue <- 0
			pool.pool_size += 1
			pool.idle_connections_length += 1

			spawn fn [mut pool] () {
				pool.add_idle_connection() or { return }
				pool.mutex.@lock()
				pool.pool_size -= 1
				pool.idle_connections_length -= 1
				pool.mutex.unlock()
				pool.free_turn()
			}()
		} else {
			return
		}
	}
}

fn (mut pool ConnectionPool) add_idle_connection() ! {
	pool.mutex.@lock()
	defer {
		pool.mutex.unlock()
	}
	new_idle_conn := pool.dial_connection(true)!
	pool.connections = arrays.concat(pool.connections, new_idle_conn)
	pool.idle_connections = arrays.concat(pool.idle_connections, new_idle_conn)
}

pub fn (mut pool ConnectionPool) new_connection() !&Connection {
	return pool.private_new_connection(false)
}

fn (mut pool ConnectionPool) private_new_connection(pooled bool) !&Connection {
	mut connection := pool.dial_connection(pooled)!

	pool.mutex.@lock()
	defer {
		pool.mutex.unlock()
	}

	pool.connections = arrays.concat(pool.connections, connection)
	if pooled {
		// If pool is full remove the connection on next put.
		if pool.pool_size >= pool.opts.pool_size {
			connection.pooled = false
		} else {
			pool.pool_size += 1
		}
	}
	return connection
}

fn (mut pool ConnectionPool) dial_connection(pooled bool) !&Connection {
	dialer_function := pool.opts.dialer()!
	mut new_conn := new_connection(dialer_function)
	new_conn.pooled = pooled
	return new_conn
}

// get returns an idle connection from the pool or creates a new one if necessary.
pub fn (mut pool ConnectionPool) get() !&Connection {
	pool.wait_turn()!
	for {
		pool.mutex.@lock()
		connection := pool.pop_idle() or {
			pool.mutex.unlock()
			break
		}
		pool.mutex.unlock()
		return connection
	}
	new_connection := pool.private_new_connection(true) or {
		pool.free_turn()
		return err
	}
	return new_connection
}

fn (mut pool ConnectionPool) wait_turn() ! {
	if pool.queue.len < pool.queue.cap {
		pool.queue <- 0
		return
	}
	// TODO add timeout to prevent potentially waiting forever
}

fn (mut pool ConnectionPool) free_turn() {
	_ := <-pool.queue
}

fn (mut pool ConnectionPool) pop_idle() !&Connection {
	length := pool.idle_connections.len
	if length == 0 {
		return error('No available idle connections')
	}
	index := length - 1
	mut popped_conn := pool.idle_connections[index]
	if index > 0 {
		pool.idle_connections = pool.idle_connections[0..index - 1]
	} else {
		pool.idle_connections = []&Connection{}
	}
	pool.idle_connections_length -= 1
	pool.check_min_idle_connections()
	return popped_conn
}

pub fn (mut pool ConnectionPool) put(mut connection Connection) ! {
	mut should_close_connection := false

	if !connection.pooled {
		pool.remove(mut connection, 'Not pooled')
		return
	}

	connection.reader.reset()
	pool.mutex.@lock()
	if pool.opts.max_idle_connections == 0
		|| pool.idle_connections_length < pool.opts.max_idle_connections {
		pool.idle_connections = arrays.concat(pool.idle_connections, connection)
		pool.idle_connections_length += 1
	} else {
		pool.remove_connection(&connection)
		should_close_connection = true
	}

	pool.mutex.unlock()
	pool.free_turn()

	if should_close_connection {
		pool.close_connection(mut connection)!
	}
}

fn (mut pool ConnectionPool) remove_connection(connection &Connection) {
	for idx, conn in pool.connections {
		// TODO id not necessary if comparing references
		// if conn.id == connection.id {
		if conn == connection {
			// Note: array.delete does not change the array in-place
			pool.connections.delete(idx)
			if connection.pooled {
				pool.pool_size -= 1
				pool.check_min_idle_connections()
			}
		}
	}
}

pub fn (mut pool ConnectionPool) close_connection(mut connection Connection) ! {
	connection.close()!
}

pub fn (mut pool ConnectionPool) close() ! {
	pool.mutex.@lock()
	for mut connection in pool.connections {
		pool.close_connection(mut connection)!
	}
	pool.connections.clear()
	pool.idle_connections.clear()
	pool.pool_size = 0
	pool.idle_connections_length = 0
	pool.mutex.unlock()
}

pub fn (mut pool ConnectionPool) remove(mut connection Connection, reason string) {
	pool.remove_connection_with_lock(mut connection)
	pool.free_turn()
	pool.close_connection(mut connection) or {}
}

fn (mut pool ConnectionPool) remove_connection_with_lock(mut connection Connection) {
	pool.mutex.@lock()
	defer {
		pool.mutex.unlock()
	}
	pool.remove_connection(connection)
}

/*
*
 *
 * SingleConnectionPool
 *
 *
*/

struct SingleConnectionPool {
mut:
	pool         Pooler
	connection   Connection
	sticky_error string
}

pub fn new_single_connection_pool(pool Pooler, connection &Connection) &SingleConnectionPool {
	return &SingleConnectionPool{
		pool: pool
		connection: connection
	}
}

pub fn (mut p SingleConnectionPool) new_connection() !&Connection {
	return p.pool.new_connection()
}

pub fn (mut p SingleConnectionPool) close_connection(mut cn Connection) ! {
	return p.pool.close_connection(mut cn)
}

pub fn (mut p SingleConnectionPool) get() !&Connection {
	if p.sticky_error != '' {
		return error(p.sticky_error)
	}
	return &p.connection
}

pub fn (mut p SingleConnectionPool) put(mut cn Connection) ! {}

pub fn (mut p SingleConnectionPool) remove(mut cn Connection, reason string) {
	p.sticky_error = reason
}

pub fn (mut p SingleConnectionPool) close() ! {
	p.sticky_error = 'closed'
}
