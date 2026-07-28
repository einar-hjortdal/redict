module redict

pub type GeoUnit = string

pub const unit_m = GeoUnit('M')
pub const unit_km = GeoUnit('KM')
pub const unit_ft = GeoUnit('FT')
pub const unit_mi = GeoUnit('MI')

pub type Sort = string

pub const asc = Sort('ASC')
pub const desc = Sort('DESC')

pub struct GeospatialItem {
pub:
	name      string
	longitude f64
	latitude  f64
}

pub struct GeoPos {
pub:
	longitude f64
	latitude  f64
}

pub struct GeoLocation {
pub:
	name string
	dist ?f64
	hash ?i64
	pos  ?GeoPos
}

pub struct GeoRadiusQuery {
pub:
	radius    f64
	unit      ?GeoUnit
	withcoord bool
	withdist  bool
	withhash  bool
	count     ?int
	sort      ?Sort
	store     ?string
	storedist ?string
}

pub struct GeoBox {
	width  f64
	height f64
}

pub struct GeoSearchQuery {
pub:
	member      ?string  // when using FROMMEMBER
	lonlat      ?GeoPos  // when using FROMLONLAT
	radius      ?f64     // when using BYRADIUS
	radius_unit ?GeoUnit // when using BYRADIUS. Defaults to unit_km
	box         ?GeoBox  // when using BYBOX
	box_unit    ?GeoUnit // when using BYBOX. Defaults to unit_km
	sort        ?Sort
	count       ?int
	count_any   bool
}

pub struct GeoSearchLocationQuery {
	GeoSearchQuery
pub:
	withcoord bool
	withdist  bool
	withhash  bool
}

pub struct GeoSearchStoreQuery {
	GeoSearchQuery
pub:
	storedist bool
}

// TODO support geoadd ch
interface GeospatialCmdable {
	geoadd(key string, geospatial_items ...GeospatialItem) &IntCmd
	// geoadd_nx
	// geoadd_xx
	geodist(key string, member_1 string, member_2 string, unit ?GeoUnit) &FloatCmd
	geohash(key string, members ...string) &StringSliceCmd
	geopos(key string, members ...string) &GeoPosCmd
	georadius(key string, longitude f64, latitude f64, q &GeoRadiusQuery) &IntCmd
	georadius_ro(key string, longitude f64, latitude f64, q &GeoRadiusQuery) &GeoLocationCmd
	georadiusbymember(key string, member string, q GeoRadiusQuery) &IntCmd
	georadiusbymember_ro(key string, member string, q GeoRadiusQuery) &GeoLocationCmd
	geosearch(key string, q GeoSearchQuery) &StringSliceCmd
	geosearch_location(key string, q GeoSearchLocationQuery) &GeoSearchLocationCmd
	geosearchstore(key string, q GeoSearchQuery) &IntCmd
}

pub fn (c CmdableFn) geoadd(key string, geospatial_items ...GeospatialItem) &IntCmd {
	mut args := []Value{len: 0, cap: geospatial_items.len * 3 + 2, init: Empty{}}
	args << 'GEOADD'
	args << key
	for _, l in geospatial_items {
		args << l.longitude
		args << l.latitude
		args << l.name
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) geodist(key string, member_1 string, member_2 string, unit ?GeoUnit) &FloatCmd {
	mut args := []Value{len: 0, cap: 5, init: Empty{}}
	args << 'GEODIST'
	args << key
	args << member_1
	args << member_2

	if u := unit {
		args << string(u)
	} else {
		args << string(unit_m)
	}

	mut cmd := new_float_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) geohash(key string, members ...string) &StringSliceCmd {
	mut args := []Value{len: 0, cap: members.len + 2, init: Empty{}}
	args << 'GEOHASH'
	args << key
	args << members

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) geopos(key string, members ...string) &GeoPosCmd {
	mut args := []Value{len: 0, cap: members.len + 2, init: Empty{}}
	args << 'GEOPOS'
	args << key
	args << members

	mut cmd := new_geo_pos_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) georadius(key string, longitude f64, latitude f64, q &GeoRadiusQuery) &IntCmd {
	if q.store == none && q.storedist == none {
		mut cmd := new_int_cmd()
		cmd.set_error(new_redict_error('georadius requires store or storedist'))
		return cmd
	}

	args := get_geo_location_args(q, 'GEORADIUS', key, longitude, latitude)
	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) georadius_ro(key string, longitude f64, latitude f64, q &GeoRadiusQuery) &GeoLocationCmd {
	if q.store != none || q.storedist != none {
		mut cmd := new_geo_location_cmd(q)
		cmd.set_error(new_redict_error('georadius_ro does not accept store nor storedist'))
		return cmd
	}

	mut cmd := new_geo_location_cmd(q, 'GEORADIUS_RO', key, longitude, latitude)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) georadiusbymember(key string, member string, q GeoRadiusQuery) &IntCmd {
	if q.store == none && q.storedist == none {
		mut cmd := new_int_cmd()
		cmd.set_error(new_redict_error('georadiusbymember requires store or storedist'))
		return cmd
	}

	args := get_geo_location_args(q, 'GEORADIUSBYMEMBER', key, member)
	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) georadiusbymember_ro(key string, member string, q GeoRadiusQuery) &GeoLocationCmd {
	if q.store != none || q.storedist != none {
		mut cmd := new_geo_location_cmd(q)
		cmd.set_error(new_redict_error('georadiusbymember_ro does not accept store nor storedist'))
		return cmd
	}

	mut cmd := new_geo_location_cmd(q, 'GEORADIUSBYMEMBER_RO', key, member)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) geosearch(key string, q GeoSearchQuery) &StringSliceCmd {
	mut args := []Value{len: 0, cap: 13, init: Empty{}}
	args << 'GEOSEARCH'
	args << key
	args << get_geosearch_args(q)

	mut cmd := new_string_slice_cmd(...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) geosearch_location(key string, q GeoSearchLocationQuery) &GeoSearchLocationCmd {
	mut args := []Value{len: 0, cap: 16, init: Empty{}}
	args << 'GEOSEARCH'
	args << key
	args << get_geo_search_location_args(q)

	mut cmd := new_geo_search_location_cmd(q, ...args)
	c(mut cmd) or {}
	return cmd
}

pub fn (c CmdableFn) geosearchstore(key string, store string, q GeoSearchStoreQuery) &IntCmd {
	mut args := []Value{len: 0, cap: 15, init: Empty{}}
	args << 'GEOSEARCHSTORE'
	args << store
	args << key
	args << get_geosearch_args(q.GeoSearchQuery)

	if q.storedist {
		args << 'STOREDIST'
	}

	mut cmd := new_int_cmd(...args)
	c(mut cmd) or {}
	return cmd
}
