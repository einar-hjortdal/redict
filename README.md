# redict

[Redict](https://redict.io/) library for the V language, [compatible with Redis <=7.2.4](https://redict.io/docs/redis-compat/).

## Usage

Install with `v install einar-hjortdal.redict`

```V
import einar_hjortdal.redict

// Configure.
ro := redict.Options{
  url: 'redict://einar:secret@localhost:6379/0' // refer to the options.v file
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
