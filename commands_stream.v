module redict

import time

// https://redict.io/docs/commands/xadd/
// only one of maxlen and minid can be used.
// approx means `~`.
pub struct XaddArgs {
pub:
	key        string
	nomkstream bool
	maxlen     ?i64
	minid      ?string
	approx     bool // ~
	limit      ?i64
	id         ?string
	values     []Value
}

// https://redict.io/docs/commands/xautoclaim/
pub struct XautoclaimArgs {
pub:
	key           string
	group         string
	min_idle_time time.Duration
	start         string
	count         ?i64
	consumer      string
}

// https://redict.io/docs/commands/xpending/
pub struct XpendingExtendedArgs {
pub:
	key      string
	group    string
	idle     ?time.Duration
	start    string
	end      string
	count    i64
	consumer ?string
}

// https://redict.io/docs/commands/xreadgroup/
pub struct XreadgroupArgs {
pub:
	group    string
	consumer string
	streams  []string
	count    ?i64
	block    ?time.Duration
	no_ack   bool
}

// https://redict.io/docs/commands/xclaim/
pub struct XclaimArgs {
pub:
	key           string
	group         string
	consumer      string
	min_idle_time time.Duration
	messages      []string
}

// https://redict.io/docs/commands/xread/
pub struct XreadArgs {
pub:
	streams []string // streams followed by ids: ['stream1', 'stream2', 'id1', id2']
	count   i64
	block   ?time.Duration
	id      ?string
}

interface StreamCmdable {
	xack(key string, group string, ids ...string) &IntCmd
	xadd(a XaddArgs) &StringCmd
	xautoclaim(a XautoclaimArgs) &XautoclaimCmd
	xautoclaim_justid(a XautoclaimArgs) &XautoclaimJustidCmd
	xclaim(a XclaimArgs) &XmessageSliceCmd
	xclaim_justid(a XclaimArgs) &StringSliceCmd
	xdel(key string, ids ...string) &IntCmd
	xgroup_create(key string, group string, start string) &StatusCmd
	xgroup_create_mkstream(key string, group string, start string) &StatusCmd
	xgroup_createconsumer(key string, group string, consumer string) &IntCmd
	xgroup_delconsumer(key string, group string, consumer string) &IntCmd
	xgroup_destroy(key string, group string) &IntCmd
	// xgroup_help
	xgroup_setid(key string, group string, start string) &StatusCmd
	xinfo_consumers(key string, group string) &XinfoConsumersCmd
	xinfo_groups(key string) &XinfoGroupsCmd
	// xinfo_help
	xinfo_stream(key string) &XinfoStreamCmd
	xinfo_stream_full(key string, count int) &XinfoStreamFullCmd
	xlen(key string) &IntCmd
	xpending(key string, group string) &XpendingCmd
	xpending_extended(a XpendingExtendedArgs) &XpendingExtendedCmd
	xrange(key string, start string, stop string) &XmessageSliceCmd
	xrange_count(key string, start string, stop string, count i64) &XmessageSliceCmd
	xread(a XreadArgs) &XstreamSliceCmd
	xreadgroup(a XreadgroupArgs) &XstreamSliceCmd
	xrevrange(key string, start string, stop string) &XmessageSliceCmd
	xrevrange_count(key string, start string, stop string, count i64) &XmessageSliceCmd
	xtrim_maxlen(key string, maxlen i64) &IntCmd
	xtrim_maxlen_approx(key string, maxlen i64, limit i64) &IntCmd
	xtrim_minid(key string, minid string) &IntCmd
	xtrim_minid_approx(key string, minid string, limit i64) &IntCmd
}

pub fn (c CmdableFn) xack(key string, group string, ids ...string) &IntCmd {
	mut args := []Value{len: 0, cap: ids.len + 3, init: Empty{}}
	args << 'XACK'
	args << key
	args << group
	args << ids

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xadd(a XaddArgs) &StringCmd {
	if a.maxlen != none && a.minid != none {
		mut cmd := new_string_cmd()
		cmd.error = new_redict_error('provide maxlen or minid, not both')
		return cmd
	}

	mut args := []Value{len: 0, cap: 11, init: Empty{}}
	args << 'XADD'
	args << a.key

	if a.nomkstream {
		args << 'NOMKSTREAM'
	}

	if maxlen := a.maxlen {
		args << 'MAXLEN'

		if a.approx {
			args << '~'
		}

		args << maxlen
	}

	if minid := a.minid {
		args << 'MINID'

		if a.approx {
			args << '~'
		}

		args << minid
	}

	if limit := a.limit {
		args << 'LIMIT'
		args << limit
	}

	if id := a.id {
		args << id
	} else {
		args << '*'
	}

	args << a.values

	mut cmd := new_string_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xautoclaim(a XautoclaimArgs) &XautoclaimCmd {
	mut args := []Value{len: 0, cap: 8, init: Empty{}}
	args << 'XAUTOCLAIM'
	args << a.key
	args << a.group
	args << a.consumer
	args << format_ms(a.min_idle_time)
	args << a.start

	if count := a.count {
		args << 'COUNT'
		args << count
	}

	mut cmd := new_xautoclaim_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xautoclaim_justid(a XautoclaimArgs) &XautoclaimJustidCmd {
	mut args := []Value{len: 0, cap: 9, init: Empty{}}
	args << 'XAUTOCLAIM'
	args << a.key
	args << a.group
	args << a.consumer
	args << format_ms(a.min_idle_time)
	args << a.start

	if count := a.count {
		args << 'COUNT'
		args << count
	}

	args << 'JUSTID'

	mut cmd := new_xautoclaim_justid_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xclaim(a XclaimArgs) &XmessageSliceCmd {
	mut args := []Value{len: 0, cap: a.messages.len + 5, init: Empty{}}
	args << 'XCLAIM'
	args << a.key
	args << a.group
	args << a.consumer
	args << format_ms(a.min_idle_time)
	args << a.messages

	mut cmd := new_xmessage_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xclaim_justid(a XclaimArgs) &StringSliceCmd {
	mut args := []Value{len: 0, cap: a.messages.len + 6, init: Empty{}}
	args << 'XCLAIM'
	args << a.key
	args << a.group
	args << a.consumer
	args << format_ms(a.min_idle_time)
	args << a.messages
	args << 'JUSTID'

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xdel(key string, ids ...string) &IntCmd {
	mut args := []Value{len: 0, cap: ids.len + 2, init: Empty{}}
	args << 'XDEL'
	args << key
	args << ids

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xgroup_create(key string, group string, start string) &StatusCmd {
	mut cmd := new_status_cmd('XGROUP', 'CREATE', key, group, start)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xgroup_create_mkstream(key string, group string, start string) &StatusCmd {
	mut cmd := new_status_cmd('XGROUP', 'CREATE', key, group, start, 'MKSTREAM')
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xgroup_createconsumer(key string, group string, consumer string) &IntCmd {
	mut cmd := new_int_cmd('XGROUP', 'CREATECONSUMER', key, group, consumer)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xgroup_delconsumer(key string, group string, consumer string) &IntCmd {
	mut cmd := new_int_cmd('XGROUP', 'DELCONSUMER', key, group, consumer)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xgroup_destroy(key string, group string) &IntCmd {
	mut cmd := new_int_cmd('XGROUP', 'DESTROY', key, group)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xgroup_setid(key string, group string, start string) &StatusCmd {
	mut cmd := new_status_cmd('XGROUP', 'SETID', key, group, start)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xinfo_consumers(key string, group string) &XinfoConsumersCmd {
	mut cmd := new_xinfo_consumers_cmd('XINFO', 'XONSUMERS', key, group)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xinfo_groups(key string) &XinfoGroupsCmd {
	mut cmd := new_xinfo_groups_cmd('XINFO', 'GROUPS', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xinfo_stream(key string) &XinfoStreamCmd {
	mut cmd := new_xinfo_stream_cmd('XINFO', 'STREAM', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xinfo_stream_full(key string, count int) &XinfoStreamFullCmd {
	mut args := []Value{len: 0, cap: 6, init: Empty{}}
	args << 'XINFO'
	args << 'STREAM'
	args << key
	args << 'FULL'

	if count > 0 {
		args << 'COUNT'
		args << count
	}

	mut cmd := new_xinfo_stream_full_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xlen(key string) &IntCmd {
	mut cmd := new_int_cmd('XLEN', key)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xpending(key string, group string) &XpendingCmd {
	mut cmd := new_xpending_cmd('XPENDING', key, group)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xpending_extended(a XpendingExtendedArgs) &XpendingExtendedCmd {
	mut args := []Value{len: 0, cap: 9, init: Empty{}}
	args << 'XPENDING'
	args << a.key
	args << a.group

	if idle := a.idle {
		args << 'IDLE'
		args << idle
	}

	args << a.start
	args << a.end
	args << a.count

	if consumer := a.consumer {
		args << consumer
	}

	mut cmd := new_xpending_extended_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xrange(key string, start string, stop string) &XmessageSliceCmd {
	mut cmd := new_xmessage_slice_cmd('XRANGE', key, start, stop)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xrange_count(key string, start string, stop string, count i64) &XmessageSliceCmd {
	mut cmd := new_xmessage_slice_cmd('XRANGE', key, start, stop, 'COUNT', count)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xread(a XreadArgs) &XstreamSliceCmd {
	mut args := []Value{len: 0, cap: a.streams.len * 2 + 6, init: Empty{}}
	args << 'XREAD'

	mut key_position := u8(1)
	if a.count > 0 {
		args << 'COUNT'
		args << a.count
		key_position += 2
	}

	if block := a.block {
		args << 'BLOCK'
		args << format_ms(block)
		key_position += 2
	}

	args << 'STREAMS'
	key_position++

	args << a.streams

	if id := a.id {
		for _, _ in a.streams {
			args << id
		}
	}

	mut cmd := new_xstream_slice_cmd(...args)
	if block := a.block {
		cmd.set_read_timeout(block)
	}
	cmd.set_first_key_pos(key_position)

	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xreadgroup(a XreadgroupArgs) &XstreamSliceCmd {
	mut args := []Value{len: 0, cap: a.streams.len + 10, init: Empty{}}
	args << 'XREADGROPUPS'
	args << 'GROUP'
	args << a.group
	args << a.consumer

	mut key_position := u8(4)
	if count := a.count {
		args << 'COUNT'
		args << count
		key_position += 2
	}

	if block := a.block {
		args << 'BLOCK'
		args << format_ms(block)
		key_position += 2
	}

	if a.no_ack {
		args << 'NOACK'
		key_position++
	}

	args << 'STREAMS'
	args << a.streams

	mut cmd := new_xstream_slice_cmd(...args)
	if block := a.block {
		cmd.set_read_timeout(block)
	}
	cmd.set_first_key_pos(key_position)

	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xrevrange(key string, start string, stop string) &XmessageSliceCmd {
	mut cmd := new_xmessage_slice_cmd('REVRANGE', key, start, stop)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xrevrange_count(key string, start string, stop string, count i64) &XmessageSliceCmd {
	mut cmd := new_xmessage_slice_cmd('REVRANGE', key, start, stop, 'COUNT', count)
	c(mut cmd) or {}
	return cmd
}

fn (c CmdableFn) xtrim(key string, strategy string, approx bool, threshold Value, limit i64) &IntCmd {
	mut args := []Value{len: 0, cap: 7, init: Empty{}}
	args << 'XTRIM'
	args << key
	args << strategy

	if approx {
		args << '~'
	}

	args << threshold

	if limit > 0 {
		args << 'LIMIT'
		args << limit
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) xtrim_maxlen(key string, maxlen i64) &IntCmd {
	return c.xtrim(key, 'MAXLEN', false, maxlen, 0)
}

pub fn (c CmdableFn) xtrim_maxlen_approx(key string, maxlen i64, limit i64) &IntCmd {
	return c.xtrim(key, 'MAXLEN', true, maxlen, limit)
}

pub fn (c CmdableFn) xtrim_minid(key string, minid string) &IntCmd {
	return c.xtrim(key, 'MINID', false, minid, 0)
}

pub fn (c CmdableFn) xtrim_minid_approx(key string, minid string, limit i64) &IntCmd {
	return c.xtrim(key, 'MINID', true, minid, limit)
}
