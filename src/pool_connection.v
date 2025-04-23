module redict

import net
// import rand
import time

pub struct PoolConnection {
pub:
	// id         string
	created_at time.Time
mut:
	connection net.TcpConn
	pooled     bool
	reader     ProtoReader
	writer     ProtoWriter
pub mut:
	initialized bool
}

fn new_pool_connection(connection net.TcpConn) &PoolConnection {
	new := &PoolConnection{
		connection: connection
		// id: rand.uuid_v4()
		created_at: time.now()
		reader:     new_reader(connection)
		writer:     new_writer(connection)
	}
	return new
}

fn (mut connection PoolConnection) close() ! {
	connection.connection.close()!
}

pub fn (mut connection PoolConnection) with_reader(func fn (mut rd ProtoReader) !) ! {
	func(mut connection.reader)!
}

pub fn (mut connection PoolConnection) with_writer(func fn (mut wr ProtoWriter) !) ! {
	func(mut connection.writer)!
}
