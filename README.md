# redict

Redict library for the V language.

## Usage

Install with `v install einar-hjortdal.redict`

```V
import einar_hjortdal.redict

// Configure.
ro := redict.Options{
  url: redict://user:pass@host:port/db // refer to the options.v file
}

// Create a new client.
client := new_client(opts)!

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
sudo docker run \
  --rm \
  --detach \
  --name=redict \
  --publish=6379:6379 \
  registry.redict.io/redict
```
