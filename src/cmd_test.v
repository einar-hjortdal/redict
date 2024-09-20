module redis

import time

/*
*
*
* Cmdable
*
*
*/

fn setup_cmdable_client() &Client {
	mut opts := Options{}
	return new_client(mut opts)
}

fn test_ping() {
	client := setup_cmdable_client()
	res := client.ping() or { panic(err) }
	assert res.val() == 'PONG'
}

fn test_set_and_get() {
	client := setup_cmdable_client()
	get_nil_res := client.get('test_key') or { panic(err) }
	assert get_nil_res.err() == 'nil'

	set_res := client.set('test_key', 'test_value', 60 * time.second) or { panic(err) }
	get_value_res := client.get('test_key') or { panic(err) }
	assert get_value_res.val() == 'test_value'
}

fn test_del() {
	client := setup_cmdable_client()
	set_res := client.set('test_key', 'test_value', 60 * time.second) or { panic(err) }
	del_res := client.del('test_key') or { panic(err) }
	assert del_res.val() == 1 // deleted one value

	get_res := client.get('test_key') or { panic(err) }
	assert get_res.err() == 'nil'
}

fn test_expire() {
	client := setup_cmdable_client()
	set_res := client.set('test_key', 'test_value', 60 * time.second) or { panic(err) }
	exp_res := client.expire('test_key', 0 * time.second) or { panic(err) }
	get_res := client.get('test_key') or { panic(err) }
	assert get_res.err() == 'nil'
}

/*
*
*
* StatefulCmdable
*
*
*/

// The HELLO command sets the RESP version to 3.
// All related tests should go here

fn setup_stateful_cmdable_client() &Client {
	// Typical settings used by peony
	mut opts := Options{
		address: 'localhost:29400'
		password: 'aed3261756c78a862013ac9a4f0d31dc1451a25a79653ff3951a2343f33245e8'
	}
	return new_client(mut opts)
}

// test_hello checks that the connections are initialized properly and RESP version 3 is used.
// To test authentication with HELLO it is nececssary to configure Redict to use password and ACL.
// The test is by default using the most common configuration with password only.
fn test_hello() {
	client := setup_stateful_cmdable_client()

	// Check authentication
	mut res := client.ping() or { panic(err) }
	assert res.val() == 'PONG'

	// Check RESP 3 nil replies
	get_nil_res := client.get('test_key') or { panic(err) }
	assert get_nil_res.err() == 'nil'
}

// TODO when trying to issue commands on a server that requires authentication, but username/password
// are not provided in the options:
// -NOAUTH HELLO must be called with the client already authenticated, otherwise the HELLO AUTH <user> <pass> option can be used to authenticate the client and select the RESP protocol version at the same time
// -NOAUTH HELLO must be called with the client already authenticated, otherwise the HELLO AUTH <user> <pass> option can be used to authenticate the client and select the RESP protocol version at the same time
// -NOAUTH HELLO must be called with the client already authenticated, otherwise the HELLO AUTH <user> <pass> option can be used to authenticate the client and select the RESP protocol version at the same time
// -NOAUTH HELLO must be called with the client already authenticated, otherwise the HELLO AUTH <user> <pass> option can be used to authenticate the client and select the RESP protocol version at the same time
// Invalid server response: response does not end with \n
