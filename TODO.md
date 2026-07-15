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
- Implement sentinel client
- Implement pipeline
- Implement pub/sub
- Implement retry_backoff

## Cmdable

- Add `do` API to issue unsupported commands
- Gracefully handle errors when issuing commands on a server that requires authentication while not 
  being authenticated.

## Reader

- `big number` can be parsed to `big.Integer`

## Writer

## Low priority

- Rewrite to avoid option initialization mutations
- Use optional function fields in options
- TLS
- Hooks: provide a way to modify or customize the behavior of specific stages in the command 
  execution process. Allow users to inject additional logic before or after a command is executed (such 
  as logging).
