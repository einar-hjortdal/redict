module redict

fn setup_options() !ParsedOptions {
	mut opts := Options{}
	return opts.init()!
}

fn test_new_connection_pool() {
	opts := setup_options()!
	mut pool := private_new_connection_pool(opts)
	pool.close()!
}

fn test_pool_get() {
	opts := setup_options()!
	mut pool := private_new_connection_pool(opts)
	conn := pool.get()!
	pool.close()!
}

// fn test_pool_put() {
// 	opts := setup_options()
// 	dialer := new_dialer(opts)!
// 	mut pool := new_connection_pool(opts, dialer)
// 	mut conn := pool.get() or { panic(err) }
// 	pool.put(mut conn) or { panic(err) } // should hang on free_turn() because of empty channel
// 	pool.close() or { panic(err) }
// }
