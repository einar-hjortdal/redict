module pool

import net
import time

fn test_new_connection() {
	mut tcp_connection := net.dial_tcp('localhost:6379') or { panic(err) }
	connection := new_connection(tcp_connection)
	assert connection.created_at.day_of_week() == time.now().day_of_week()
	tcp_connection.close() or { panic(err) }
}
