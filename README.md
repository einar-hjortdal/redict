# redict

Redict library for the V language.

## Current features

- RESP version 3
- [Commands](src/cmdable.v)
- Connection pool

## Usage

Install with `v install einar-hjortdal.redict`

```V
import einar-hjortdal.redict

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

## Notes

### Objectives 

- Provide a driver for [Redict](https://redict.io/)
- Support all [Redict commands](https://redict.io/docs/commands/)
- Provide utility functions

### Non-objectives

- Support [features not supported by Redict](https://redict.io/docs/redis-compat/)

### Contributing

Pull requests are very welcome. Please look at [CONTRIBUTING.md](./CONTRIBUTING.md) and at [TODO.md](./TODO.md) 
files. Open issues for problems you encounter, reach out to me and the other contributors on [V's Discord](https://discord.gg/vlang).
