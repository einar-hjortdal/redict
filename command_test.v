module redict

import time

fn setup_cmdable_client() !&Client {
	opts := Options{}
	return new_client(opts)
}

fn test_ping() {
	mut client := setup_cmdable_client()!
	v := client.ping().result()!
	println(client.ping())
	assert v == 'PONG'
}

fn test_get_unset() {
	client := setup_cmdable_client()!
	r := client.get('set_key')
	r.result() or { assert is_nil(err) }
}

fn test_set_and_get() {
	client := setup_cmdable_client()!
	client.set('set_key', 'test_value', 60 * time.second)
	get_res := client.get('set_key')
	v := get_res.value()
	assert v == 'test_value'
}

fn test_del() {
	client := setup_cmdable_client()!
	client.set('set_key', 'test_value', 60 * time.second)
	del_res := client.del('set_key')
	assert del_res.value() == 1

	get_res := client.get('set_key')
	get_res.result() or { assert is_nil(err) }
}

fn test_expire() {
	client := setup_cmdable_client()!
	client.set('set_key', 'test_value', 60 * time.second)
	client.expire('set_key', 0 * time.second)
	get_res := client.get('set_key')
	get_res.result() or { assert is_nil(err) }
}

fn test_hset() {
	client := setup_cmdable_client()!
	a := [Value('some key'), 'some value', 'last key', 'last value']
	hset_res := client.hset('hash_key', a)
}

fn test_hget() {
	client := setup_cmdable_client()!
	a := [Value('some key'), 'some value']
	client.hset('hash_key', a)
	hget_res := client.hget('hash_key', 'some key')
	assert hget_res.value() == 'some value'
}

fn setup_stateful_cmdable_client() !&Client {
	opts := Options{
		url: ':aed3261756c78a862013ac9a4f0d31dc1451a25a79653ff3951a2343f33245e8@'
	}
	return new_client(opts)!
}

// test_hello checks that the connections are initialized properly and RESP version 3 is used.
// To test authentication with HELLO it is nececssary to configure Redict to use password and ACL.
// The test is by default using the most common configuration with password only.
fn test_hello() {
	client := setup_stateful_cmdable_client()!

	// Check authentication
	mut res := client.ping()
	assert res.value() == 'PONG'

	// Check RESP 3 nil replies
	get_nil_res := client.get('hello_key')
	get_nil_res.result() or { assert is_nil(err) }
}

