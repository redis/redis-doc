This command works exactly like `EXPIRE` but the time-to-live of the _key_ is specified in milliseconds instead of seconds.

## Options

The `PEXPIRE` command supports a set of options since Redis 7.0:

* `NX` -- Set expiry only when the key has no expiry.
* `XX` -- Set expiry only when the key has an existing expiry.
* `GT` -- Set expiry only when the new expiry is greater than the current one.
* `LT` -- Set expiry only when the new expiry is less than the current one.

A non-volatile key is treated as having an infinite TTL when called with `GT` and `LT`.
The `GT`, `LT` and `NX` options are mutually exclusive.

@return

@integer-reply, specifically:

* `1` if the timeout was set.
* `0` if the timeout wasn't set. e.g. _key_ doesn't exist, or the operation was skipped due to the provided arguments.

@examples

```cli
SET mykey "Hello"
PEXPIRE mykey 1500
TTL mykey
PTTL mykey
PEXPIRE mykey 1000 XX
TTL mykey
PEXPIRE mykey 1000 NX
TTL mykey
```
