module proto

const resp_status = '+' // +<string>\r\n
const resp_error = '-' // -<string>\r\n
const resp_string = '$' // $<length>\r\n<bytes>\r\n
const resp_int = ':' // :<number>\r\n
const resp_nil = '_' // _\r\n
const resp_float = ',' // ,<floating-point-number>\r\n
const resp_bool = '#' // true: #t\r\n false: #f\r\n
const resp_blob_error = '!' // !<length>\r\n<bytes>\r\n
const resp_verbatim = '=' // =<length>\r\nFORMAT:<bytes>\r\n
const resp_big_int = '(' // (<big number>\r\n
const resp_array = '*' // *<len>\r\n...
const resp_map = '%' // %<len>\r\n(key)\r\n(value)\r\n...
const resp_set = '~' // ~<len>\r\n...
const resp_attr = '|' // |<len>\r\n(key)\r\n(value)\r\n... + command reply
const resp_push = '>' // ><len>\r\n...
const resp_crlf = '\r\n'
const resp_streamed = 'EOF:'
const resp_streamed_aggregated = '?'
