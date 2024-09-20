module proto

const (
	resp_status              = '+' // +<string>\r\n
	resp_error               = '-' // -<string>\r\n
	resp_string              = '$' // $<length>\r\n<bytes>\r\n
	resp_int                 = ':' // :<number>\r\n
	resp_nil                 = '_' // _\r\n
	resp_float               = ',' // ,<floating-point-number>\r\n
	resp_bool                = '#' // true: #t\r\n false: #f\r\n
	resp_blob_error          = '!' // !<length>\r\n<bytes>\r\n
	resp_verbatim            = '=' // =<length>\r\nFORMAT:<bytes>\r\n
	resp_big_int             = '(' // (<big number>\r\n
	resp_array               = '*' // *<len>\r\n...
	resp_map                 = '%' // %<len>\r\n(key)\r\n(value)\r\n...
	resp_set                 = '~' // ~<len>\r\n...
	resp_attr                = '|' // |<len>\r\n(key)\r\n(value)\r\n... + command reply
	resp_push                = '>' // ><len>\r\n...
	resp_crlf                = '\r\n'
	resp_streamed            = 'EOF:'
	resp_streamed_aggregated = '?'
)
