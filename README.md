This project is active: new features are being developed, bugs are being fixed.

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

## Features

- Connection pool
- Supported commands:
  - [connection](./commands.v)
  - [generic](./commands_generic.v)
  - [hash](./commands_hash.v)
  - [set](./commands_set.v)
  - [string](./commands_string.v)

## Objectives

- Support all [Redict commands](https://redict.io/docs/commands/)
- [Pub/Sub](https://redict.io/docs/usage/pubsub/)
- [Transactions](https://redict.io/docs/usage/transactions/)
- [Pipelines](https://redict.io/docs/usage/pipelining/)
- [Redict Sentinel](https://redict.io/docs/usage/sentinel/)
- [Redict Cluster](https://redict.io/docs/usage/scaling/)
- Provide utility functions

## Development

- [Issues](https://github.com/einar-hjortdal/redict/issues)
- [TODO.md](./TODO.md)
- [CONTRIBUTING.md](./CONTRIBUTING.md)

```bash
# Start a Redict container
docker run \
  --rm \
  --detach \
  --name=redict \
  --publish=6379:6379 \
  registry.redict.io/redict
```
