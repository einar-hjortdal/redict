module redict

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
