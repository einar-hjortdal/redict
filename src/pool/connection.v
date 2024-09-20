module pool

import net
// import rand
import time
import proto

pub struct Connection {
pub:
	// id         string
	created_at time.Time
mut:
	connection net.TcpConn
	pooled     bool
	reader     proto.Reader
	writer     proto.Writer
pub mut:
	initialized bool
}

fn new_connection(connection net.TcpConn) &Connection {
	new := &Connection{
		connection: connection
		// id: rand.uuid_v4()
		created_at: time.now()
		reader: proto.new_reader(connection)
		writer: proto.new_writer(connection)
	}
	return new
}

fn (mut connection Connection) close() ! {
	connection.connection.close()!
}

pub fn (mut connection Connection) with_reader(func fn (mut rd proto.Reader) !) ! {
	func(mut connection.reader)!
}

pub fn (mut connection Connection) with_writer(func fn (mut wr proto.Writer) !) ! {
	func(mut connection.writer)!
}
