module redict

import net
import time

@[heap]
struct PoolConnection {
	created_at time.Time
mut:
	// used_at atomic
	connection  &net.TcpConn
	pooled      bool
	reader      &ProtoReader
	writer      &ProtoWriter
	initialized bool
}

fn new_pool_connection(mut connection net.TcpConn) &PoolConnection {
	new := &PoolConnection{
		connection: connection
		created_at: time.now()
		reader:     new_reader(mut connection)
		writer:     new_writer(mut connection)
	}
	return new
}

fn (mut pc PoolConnection) close() ! {
	pc.connection.close()!
}

// TODO needs context param
fn (mut pc PoolConnection) deadline(timeout time.Duration) time.Time {
	now := time.now()
	// pc.set_used_at(now)

	t := now.add(timeout)
	// TODO set context deadline

	if timeout > 0 {
		return t
	}

	return time.Time{}
}

fn (mut pc PoolConnection) with_reader(timeout time.Duration, func fn (mut rd ProtoReader) !) ! {
	pc.connection.set_read_deadline(pc.deadline(timeout))
	func(mut pc.reader)!
}

fn (mut pc PoolConnection) with_writer(func fn (mut wr ProtoWriter) !) ! {
	func(mut pc.writer)!
}
