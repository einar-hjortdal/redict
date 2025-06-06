module redict

import net
import time

@[heap]
struct PoolConnection {
	created_at time.Time
mut:
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

fn (mut pc PoolConnection) with_reader(func fn (mut rd ProtoReader) !) ! {
	func(mut pc.reader)!
}

fn (mut pc PoolConnection) with_writer(func fn (mut wr ProtoWriter) !) ! {
	func(mut pc.writer)!
}
