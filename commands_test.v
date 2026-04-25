import os
import redict
import time

const redict_container_name = 'einar_hjortdal-redict'
const redict_port = '6381'

fn container_clean() {
	result := os.execute('docker stop ${redict_container_name}')
	if result.exit_code != 0 {
		if result.output.contains('No such container') {
			return
		}
		eprintln(result.output)
	}
}

// Remember to `sudo usermod -aG docker $USER`
fn container_start() ! {
	container_clean() // kill container if already running
	result :=
		os.execute('docker run --rm --detach --name=${redict_container_name} --publish=${redict_port}:6379 registry.redict.io/redict')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn container_is_ready() {
	mut redict_is_loading := true
	for redict_is_loading {
		ping := os.execute('docker exec ${redict_container_name} redict-cli ping')
		if ping.output.contains('PONG') {
			redict_is_loading = false
		}

		time.sleep(1 * time.second)
	}
	return
}

fn testsuite_begin() ! {
	container_start()!
	container_is_ready()
}

fn testsuite_end() ! {
	container_clean()
}

fn setup_cmdable_client() !&redict.Client {
	return redict.new_client(redict.Options{
		url: '@localhost:${redict_port}/0'
	})
}

// uncategorized

fn test_ping() {
	mut client := setup_cmdable_client()!
	v := client.ping().result()!
	assert v == 'PONG'
}

// string

fn test_get_unset() {
	client := setup_cmdable_client()!
	client.get('set_key').result() or { assert redict.is_nil(err) }
}

fn test_set_and_get() {
	expected := 'test_value'
	client := setup_cmdable_client()!
	client.set('set_key', expected, 60 * time.second).result()!
	v := client.get('set_key').result()!
	assert v == expected
}

// generic

fn test_del() {
	client := setup_cmdable_client()!
	client.set('set_key', 'test_value', 60 * time.second).result()!
	v := client.del('set_key').result()!
	assert v == 1

	client.get('set_key').result() or { assert redict.is_nil(err) }
}

fn test_expire() {
	client := setup_cmdable_client()!
	client.set('set_key', 'test_value', 60 * time.second).result()!
	client.expire('set_key', 0 * time.second)
	client.get('set_key').result() or { assert redict.is_nil(err) }
}

fn test_hdel() {
	client := setup_cmdable_client()!
	client.hset('hash', 'key', 'hello').result()!
	mut v := client.hdel('hash', 'key').result()!
	assert v == 1
	v = client.hdel('hash', 'key').result()!
	assert v == 0
}

fn test_hget() {
	client := setup_cmdable_client()!
	client.hset('hash', 'key', 'hello').result()!
	v := client.hget('hash', 'key').result()!
	assert v == 'hello'
}
