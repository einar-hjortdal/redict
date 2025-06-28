# TODO

## Features

- `Context`
- Support RESP2

## Throughout

- Add tests
- Add logger

## Options

- Add support for unix socket connections

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

- Change the type of `Cmdable.set` paramter `value` to be `Value` instead of `string`.
- Format `BaseCmd.string_arg` returned string with `append_arg` instead of using string interpolation.

## Cmdable

- Add `do` API to issue unsupported commands
- Gracefully handle errors when issuing commands on a server that requires authentication while not 
  being authenticated.

## Reader

- `big number` can be parsed to `big.Integer`

## Writer
