module redict

import net
import runtime
import time
import net.urllib

const error_cluster_no_nodes = error(format_error_message('cluster has no nodes'))

struct ClusterNode {
	latency    uint32 // atomic
	generation uint32 // atomic
	failing    uint32 // atomic
mut:
	client &Client
}

pub struct ClusterOptions {
pub:
	client_name      string
	route_by_latency bool
	route_randomly   bool
	cluster_slots    fn () ![]ClusterSlot @[required]
	dialer           fn (network string, address string) !net.TcpConn @[required]
	on_connect       ?fn (mut cn Connection) !
pub mut:
	addresses         []string
	new_client        ?fn (options Options) !&Client
	max_redirects     int
	read_only         bool
	pool_size         int // per node
	read_timeout      time.Duration
	write_timeout     time.Duration
	max_retries       int
	min_retry_backoff time.Duration
	max_retry_backoff time.Duration
}

fn (o ClusterOptions) get_max_redirects() int {
	match o.max_redirects {
		-1 {
			return 0
		}
		0 {
			return 3
		}
		else {
			return o.max_redirects
		}
	}
}

fn (o ClusterOptions) getread_only() bool {
	return o.route_by_latency || o.route_randomly
}

fn (o ClusterOptions) getread_pool_size() int {
	if o.pool_size == 0 {
		return 5 * runtime.nr_cpus()
	}
	return o.pool_size
}

fn (o ClusterOptions) getread_read_timeout() time.Duration {
	match o.read_timeout {
		-1 {
			return 0
		}
		0 {
			return 3 * time.second
		}
		else {
			return o.read_timeout
		}
	}
}

fn (o ClusterOptions) get_write_timeout() time.Duration {
	match o.write_timeout {
		-1 {
			return 0
		}
		0 {
			return o.read_timeout
		}
		else {
			return o.write_timeout
		}
	}
}

fn (mut o ClusterOptions) get_max_retries() int {
	if o.max_retries == 0 {
		return -1
	}
	return o.max_retries
}

fn (mut o ClusterOptions) get_min_retry_backoff() time.Duration {
	match o.min_retry_backoff {
		-1 {
			return 0
		}
		0 {
			return 8 * time.millisecond
		}
		else {
			return o.min_retry_backoff
		}
	}
}

fn (mut o ClusterOptions) get_max_retry_backoff() time.Duration {
	match o.max_retry_backoff {
		-1 {
			return 0
		}
		0 {
			return 512 * time.millisecond
		}
		else {
			return o.max_retry_backoff
		}
	}
}

fn (mut o ClusterOptions) get_new_client() fn (options Options) !&Client {
	new_client_fn := o.new_client or { return new_client }
	return new_client_fn
}

fn (mut o ClusterOptions) init() {
	o.max_redirects = o.get_max_redirects()
	o.read_only = o.getread_only()
	o.read_timeout = o.getread_read_timeout()
	o.write_timeout = o.get_write_timeout()
	o.max_retries = o.get_max_retries()
	o.min_retry_backoff = o.get_min_retry_backoff()
	o.max_retry_backoff = o.get_max_retry_backoff()
	o.new_client = o.get_new_client()
}

fn (mut o ClusterOptions) setup_cluser_conn(u urllib.URL, host string) ! {
	match u.scheme {
		'redicts' {
			return error('TLS is not currently supported')
		}
		'redict' {
			o.username, o.password = get_user_password(u)
		}
		else {
			return error('invalid URL scheme: `${u.scheme}`')
		}
	}
}

struct ClusterClient {
	CmdableFn
	options         &ClusterOptions
	nodes           &ClusterNodes
	state           &ClusterStateHolder
	cmds_info_cache &CmdsInfoCache
}

// somewhat like https://cs.opensource.google/go/go/+/refs/tags/go1.26.5:src/net/ipsock.go;l=165
fn split_host_port(hostport string) !(string, string) {
	mut host := ''
	mut port := ''
	last_colon := hostport.last_index(':') or { return error('missing port in address') }
	if hostport[0] == `[` {
		closing_bracket := hostport.index(']') or { return error('missing `]` in address') }
		match closing_bracket + 1 {
			hostport.len {
				return error('missing port in address')
			}
			last_colon {}
			else {
				if hostport[closing_bracket + 1] == `:` {
					return error('too many `:`')
				}
				return error('missing port in address')
			}
		}

		host = hostport[1..closing_bracket]
	} else {
		host = hostport[..last_colon]
		if host.contains(':') { return error('too many `:`') }
	}

	if host.contains('[') { return error('unexpected `[` in address]') }
	if host.contains(']') { return error('unexpected `]` in address]') }

	port = hostport[last_colon + 1..]
	return host, port
}

// if invalid host/port or missing port, returns localhost 6379
fn split_host_port_with_defaults(redict_url urllib.URL) (string, string) {
	host, port := split_host_port(redict_url.host) or { return 'localhost', '6379' }
	return host, port
}

fn join_host_port(host string, port string) string {
	if host.contains(':') {
		return '[${host}]:${port}'
	}
	return '${host}:${port}'
}

fn parse_cluster_url(redict_url string) !&ClusterOptions {
	mut o := &ClusterOptions{}
	u := urllib.parse(redict_url)!
	host, port := split_host_port_with_defaults(u)
	o.addresses << join_host_port(host, port)
	o.setup_cluser_conn(u, host)!
}
