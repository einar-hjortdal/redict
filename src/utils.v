module redict

import x.json2 as json

const lib = 'redict'

fn format_error_message(message string) string {
	return '[${lib}] ${message}'
}

fn to_lower(s string) string {
	if s.is_lower() {
		return s
	} else {
		return s.to_lower()
	}
}

fn hset_append(args []json.Any, values json.Any) ![]json.Any {
	mut res := args.clone()
	match values {
		[]json.Any {
			for i := 0; i < values.len; i++ {
				res << values[i]
			}
		}
		map[string]json.Any {
			for key, val in values {
				res << key
				res << val
			}
		}
		else {
			return error(format_error_message('hset received unsupported type'))
		}
	}
	return res
}
