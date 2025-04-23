# TODO

## Features

- `Context`
- Support RESP2

## Throughout

- Add tests
- Add logger
- Verify structs are being passed by reference when needed

## Options

- Add support for unix socket connections
- Parse connection strings with net.URL

## Pool

- Consider removing pool entirely and let user handle pooling
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
- Gracefully handle errors when issuing commands on a server that requires authentication while not 
  being authenticated.

## Reader

- `big number` can be parsed to `big.Integer`

## Writer
