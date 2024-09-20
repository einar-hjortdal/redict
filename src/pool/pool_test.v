import pool
import time

// RUNTIME ERROR: invalid memory access
// because pool.dial_connection attempts to use uninitialized pool.dialer
fn new_opts() &pool.Options {
	return &pool.Options{
		pool_size: 10
	}
}

fn new_pool() &pool.ConnectionPool {
	return pool.new_connection_pool(new_opts())
}

fn test_unblock_when_conn_removed() {
	println(new_opts())
	mut conn_pool := new_pool()
	// reserve one connection
	mut cn := conn_pool.get()!

	// reserve the rmaining connections
	mut cns := []&pool.Connection{}
	for i := 0; i < 9; i++ {
		loop_cn := conn_pool.get()!
		cns << loop_cn
	}

	started := chan bool{}
	done := chan bool{}

	spawn fn [mut conn_pool, mut cn, started, done] () ! {
		started <- true
		_ := conn_pool.get()!
		done <- true
		conn_pool.put(mut cn)!
	}()
	_ := <-started

	for {
		if case := <-done {
			eprintln('.get() is not blocked')
			assert false
			return
		}
		time.sleep(time.millisecond)
		break
	}

	conn_pool.remove(mut cn, 'test_unblock_when_conn_removed')

	for {
		if case := <-done {
			assert true
			break
		}
		time.sleep(time.millisecond)
		eprintln('.get() is blocked')
		assert false
		return
	}
}
