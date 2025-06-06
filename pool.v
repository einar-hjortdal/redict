module redict

import arrays
import net
import sync
// import time

interface Pooler {
mut:
	new_connection() !&PoolConnection
	close_connection(mut PoolConnection) !
	get() !&PoolConnection
	put(mut PoolConnection) !
	remove(mut PoolConnection, string)
	close() !
}

struct PoolOptions {
	min_idle_connections int
	max_idle_connections int
	dialer               fn () !&net.TcpConn = unsafe { nil }
	pool_size            int
}

pub struct ConnectionPool {
	opts  PoolOptions
	queue chan int
mut:
	// connections contains the currently active connections.
	connections []&PoolConnection
	// idle_connections contains the currently available connections.
	idle_connections []&PoolConnection
	// idle_connections_length is the number of currently available connections.
	idle_connections_length int
	// pool_size is the current number of connections in the pool.
	pool_size int
	mutex     &sync.Mutex
}

fn new_connection_pool(opts PoolOptions) &ConnectionPool {
	mut p := &ConnectionPool{
		opts:             opts
		queue:            chan int{cap: opts.pool_size}
		connections:      []&PoolConnection{}
		idle_connections: []&PoolConnection{}
		mutex:            sync.new_mutex()
	}

	p.mutex.@lock()
	p.check_min_idle_connections()
	p.mutex.unlock()

	return p
}

fn (mut p ConnectionPool) check_min_idle_connections() {
	if p.opts.min_idle_connections == 0 {
		return
	}
	for p.pool_size < p.opts.pool_size && p.idle_connections_length < p.opts.min_idle_connections {
		if p.queue.len < p.queue.cap {
			p.queue <- 0
			p.pool_size++
			p.idle_connections_length++

			go fn [mut p] () {
				p.add_idle_connection() or { return }
				p.mutex.@lock()
				p.pool_size--
				p.idle_connections_length--
				p.mutex.unlock()
				p.free_turn()
			}()
		} else {
			return
		}
	}
}

fn (mut cp ConnectionPool) add_idle_connection() ! {
	cp.mutex.@lock()
	defer {
		cp.mutex.unlock()
	}
	new_idle_conn := cp.dial_connection(true)!
	cp.connections = arrays.concat(cp.connections, new_idle_conn)
	cp.idle_connections = arrays.concat(cp.idle_connections, new_idle_conn)
}

fn (mut pool ConnectionPool) new_connection() !&PoolConnection {
	return pool.private_new_connection(false)
}

fn (mut p ConnectionPool) private_new_connection(pooled bool) !&PoolConnection {
	mut pc := p.dial_connection(pooled)!

	p.mutex.@lock()
	p.connections = arrays.concat(p.connections, pc)
	if pooled {
		// If pool is full remove the connection on next put.
		if p.pool_size >= p.opts.pool_size {
			pc.pooled = false
		} else {
			p.pool_size++
		}
	}
	p.mutex.unlock()

	return pc
}

fn (mut p ConnectionPool) dial_connection(pooled bool) !&PoolConnection {
	mut c := p.opts.dialer()!
	mut pc := new_pool_connection(mut c)
	pc.pooled = pooled
	return pc
}

// get returns an idle connection from the pool or creates a new one if necessary.
fn (mut cp ConnectionPool) get() !&PoolConnection {
	cp.wait_turn()!
	for {
		cp.mutex.@lock()
		pc := cp.pop_idle() or {
			cp.mutex.unlock()
			break
		}
		cp.mutex.unlock()
		return pc
	}
	new_pc := cp.private_new_connection(true) or {
		cp.free_turn()
		return err
	}
	return new_pc
}

// TODO add timeout to prevent potentially waiting forever
fn (mut cp ConnectionPool) wait_turn() ! {
	if cp.queue.len < cp.queue.cap {
		cp.queue <- 0
		return
	}
}

fn (mut cp ConnectionPool) free_turn() {
	_ := <-cp.queue
}

fn (mut pool ConnectionPool) pop_idle() !&PoolConnection {
	length := pool.idle_connections.len
	if length == 0 {
		return error(format_error_message('No available idle connections'))
	}
	index := length - 1
	mut popped_conn := pool.idle_connections[index]
	if index > 0 {
		pool.idle_connections = pool.idle_connections[0..index - 1]
	} else {
		pool.idle_connections = []&PoolConnection{}
	}
	pool.idle_connections_length--
	pool.check_min_idle_connections()
	return popped_conn
}

fn (mut pool ConnectionPool) put(mut connection PoolConnection) ! {
	mut should_close_connection := false

	if !connection.pooled {
		pool.remove(mut connection, 'Not pooled')
		return
	}

	pool.mutex.@lock()
	if pool.opts.max_idle_connections == 0
		|| pool.idle_connections_length < pool.opts.max_idle_connections {
		pool.idle_connections = arrays.concat(pool.idle_connections, connection)
		pool.idle_connections_length++
	} else {
		pool.remove_connection(connection)
		should_close_connection = true
	}

	pool.mutex.unlock()
	pool.free_turn()

	if should_close_connection {
		pool.close_connection(mut connection)!
	}
}

fn (mut cp ConnectionPool) remove_connection(pc &PoolConnection) {
	for i := 0; i < cp.connections.len; i++ {
		c := cp.connections[i]
		if c == pc {
			cp.connections.delete(i)
			if c.pooled {
				cp.pool_size--
				cp.check_min_idle_connections()
			}
		}
	}
}

fn (mut cp ConnectionPool) close_connection(mut pc PoolConnection) ! {
	pc.close()!
}

fn (mut p ConnectionPool) close() ! {
	p.mutex.@lock()
	for i := 0; i < p.connections.len; i++ {
		p.close_connection(mut p.connections[i])!
	}
	p.connections.clear()
	p.idle_connections.clear()
	p.pool_size = 0
	p.idle_connections_length = 0
	p.mutex.unlock()
}

fn (mut cp ConnectionPool) remove(mut connection PoolConnection, reason string) {
	cp.remove_connection_with_lock(mut connection)
	cp.free_turn()
	cp.close_connection(mut connection) or {}
}

fn (mut cp ConnectionPool) remove_connection_with_lock(mut pc PoolConnection) {
	cp.mutex.@lock()
	defer {
		cp.mutex.unlock()
	}
	cp.remove_connection(pc)
}

struct SingleConnectionPool {
mut:
	pool         &Pooler
	connection   &PoolConnection
	sticky_error string
}

fn new_single_connection_pool(mut pool Pooler, mut connection PoolConnection) &SingleConnectionPool {
	return &SingleConnectionPool{
		pool:       pool
		connection: connection
	}
}

fn (mut scp SingleConnectionPool) new_connection() !&PoolConnection {
	return scp.pool.new_connection()
}

fn (mut scp SingleConnectionPool) close_connection(mut cn PoolConnection) ! {
	return scp.pool.close_connection(mut cn)
}

fn (mut scp SingleConnectionPool) get() !&PoolConnection {
	if scp.sticky_error != '' {
		return error(scp.sticky_error)
	}
	return scp.connection
}

fn (mut scp SingleConnectionPool) put(mut cn PoolConnection) ! {}

fn (mut scp SingleConnectionPool) remove(mut cn PoolConnection, reason string) {
	scp.sticky_error = reason
}

fn (mut scp SingleConnectionPool) close() ! {
	scp.sticky_error = 'closed'
}
