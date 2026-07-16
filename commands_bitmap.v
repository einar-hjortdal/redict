module redict

pub const bit_count_index_byte = 'BYTE'
pub const bit_count_index_bit = 'BIT'

pub struct BitCount {
pub:
	start i64
	end   i64
	unit  ?string
}

pub interface BitMapCmdable {
	bitcount(key string, bit_count ?BitCount) &IntCmd
	bitfield(key string, values ...Value) &IntSliceCmd
	bitfield_ro(key string, values ...Value) &IntSliceCmd
	bitopand(dest_key string, keys ...string) &IntCmd
	bitopor(dest_key string, keys ...string) &IntCmd
	bitopxor(dest_key string, keys ...string) &IntCmd
	bitopnot(dest_key string, keys ...string) &IntCmd
	bitpos(key string, bit i64, pos ...i64) &IntCmd
	getbit(key string, offset i64) &IntCmd
	setbit(key string, offset i64, value int) &IntCmd
}

pub fn (c CmdableFn) bitcount(key string, bit_count ?BitCount) &IntCmd {
	mut args := []Value{len: 0, cap: 5, init: Value(Empty{})}
	args << 'BITCOUNT'
	args << key

	if bc := bit_count {
		args << bc.start
		args << bc.end

		if unit := bc.unit {
			if unit != bit_count_index_byte && unit != bit_count_index_bit {
				mut cmd := new_int_cmd()
				cmd.error = new_redict_error('invalid bitcount index')
				return cmd
			}
			args << unit
		}
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) bitfield(key string, values ...Value) &IntSliceCmd {
	mut args := []Value{len: 0, cap: values.len + 2, init: Value(Empty{})}
	args << 'BITFIELD'
	args << key
	args << values

	mut cmd := new_int_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) bitfield_ro(key string, values ...Value) &IntSliceCmd {
	if values.len % 2 != 0 {
		mut cmd := new_int_slice_cmd()
		cmd.error = new_redict_error('bitfield_ro received uneven number of values')
		return cmd
	}

	mut args := []Value{len: 0, cap: values.len + 2, init: Value(Empty{})}
	args << 'BITFIELD_RO'
	args << key
	args << values

	mut cmd := new_int_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

fn (c CmdableFn) bitop(op string, dest_key string, keys ...string) &IntCmd {
	mut args := []Value{len: 0, cap: keys.len + 3, init: Value(Empty{})}
	args << 'BITOP'
	args << op
	args << dest_key
	args << keys

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) bitopand(dest_key string, keys ...string) &IntCmd {
	return c.bitop('AND', dest_key, keys)
}

pub fn (c CmdableFn) bitopor(dest_key string, keys ...string) &IntCmd {
	return c.bitop('OR', dest_key, keys)
}

pub fn (c CmdableFn) bitopxor(dest_key string, keys ...string) &IntCmd {
	return c.bitop('XOR', dest_key, keys)
}

pub fn (c CmdableFn) bitopnot(dest_key string, keys ...string) &IntCmd {
	return c.bitop('NOT', dest_key, keys)
}

pub fn (c CmdableFn) bitpos(key string, bit i64, pos ...i64) &IntCmd {
	if pos.len > 2 {
		mut cmd := new_int_cmd()
		cmd.error = new_redict_error('bitpos received too many pos')
		return cmd
	}

	mut args := []Value{len: 0, cap: pos.len + 3, init: Value(Empty{})}
	args << 'BITPOS'
	args << key
	args << bit
	args << pos

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) getbit(key string, offset i64) &IntCmd {
	mut cmd := new_int_cmd('GETBIT', key, offset)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) setbit(key string, offset i64, value int) &IntCmd {
	mut cmd := new_int_cmd('SETBIT', key, offset, value)
	c(mut cmd) or {}
	return cmd
}
