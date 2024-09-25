# redict

Redict library for the V language.

## Current features

- RESP version 3
- [Commands](src/cmdable.v)
- Connection pool

## Usage

Install with `v install einar-hjortdal.redict`

```V
import einar_hjortdal.redict

// Configure.
mut ro := redict.Options{
  // refer to the options.v file
}

// Create a new client.
client := new_client(mut opts)

// Issue commands as Client methods.
// Supported commands are listed in the `cmdable.v` file.
mut result := client.set('test_key', 'test_value', 0)!

// Get the value from results
result = client.get('test_key')!
println(result.val())
```

## Objectives 

- Provide a driver for [Redict](https://redict.io/)
- Support all [Redict commands](https://redict.io/docs/commands/)
- Provide utility functions

### Non-objectives

- Support [features not supported by Redict](https://redict.io/docs/redis-compat/)

## Development

- [Issues](https://github.com/einar-hjortdal/redict/issues)
- [TODO.md](./TODO.md)
- [CONTRIBUTING.md](./CONTRIBUTING.md)

```bash
# Start a Redict container
podman run \
  --rm \
  --detach \
  --name=redict \
  --tz=local \
  --publish=6379:6379 \
  registry.redict.io/redict
```
