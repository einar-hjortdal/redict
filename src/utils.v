module redis

fn to_lower(s string) string {
	if s.is_lower() {
		return s
	} else {
		return s.to_lower()
	}
}
