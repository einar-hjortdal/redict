module redict

import net
import time

fn test_new_connection() {
	mut tcp_connection := net.dial_tcp('localhost:6379')!
	pool_connection := new_pool_connection(mut tcp_connection)
	assert pool_connection.created_at.day_of_week() == time.now().day_of_week()
	tcp_connection.close()!
}
