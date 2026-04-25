// stateful

fn setup_stateful_cmdable_client() !&Client {
	opts := Options{
		url: ':aed3261756c78a862013ac9a4f0d31dc1451a25a79653ff3951a2343f33245e8@localhost:${redict_port}/0'
	}
	return new_client(opts)!
}

// test_hello checks that the connections are initialized properly and RESP version 3 is used.
// To test authentication with HELLO it is nececssary to configure Redict to use password and ACL.
// The test is by default using the most common configuration with password only.
fn test_hello() {
	client := setup_stateful_cmdable_client()!

	// Check authentication
	v := client.ping().result()!
	assert v == 'PONG'

	// Check RESP 3 nil replies
	client.get('hello_key').result() or { assert is_nil(err) }
}

