# TODO

## Features

- `Context`
- Support RESP2

## Throughout

- Eliminate `json2.Any`, replace with empty interface
- Add tests
- Add logger
- Verify structs are being passed by reference when needed

## Options

- Add support for unix socket connections
- Parse connection strings with net.URL

## Pool

- Add timeout
- Max idle time
- Max life time
- implement `StickyConnectionPool`

## Client

- Implement cluster client
- Implement pipeline
- Implement pub/sub
- Implement retry_backoff
- Handle errors properly
- Implement hooks: provide a way to modify or customize the behavior of specific stages in the command 
  execution process. Allow users to inject additional logic before or after a command is executed (such 
  as logging).

## Cmd

- Format `BaseCmd.string_arg` returned string with `append_arg` instead of using string interpolation.

## Cmdable

- Support all commands listed [here](https://redict.io/docs/commands)
- Add `do` API to issue unsupported commands
- `get` should return a `nil` result instead of an error when `key` does not exist. At the moment, Cmdable 
  returns an error with a string `'nil'`. It would be better to return the struct `Nil`. 
- Gracefully handle errors when issuing commands on a server that requires authentication while not 
  being authenticated.

## Proto

### Reader

- `big number` can be parsed to `big.Integer`

### Writer
