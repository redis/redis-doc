Returns the remaining time-to-live (TTL) of a _key_.

This introspection capability allows a Redis client to check how many seconds a given key will continue to be part of the dataset.

In Redis 2.6 and older, the command returns `-1` if the key doesn't exist or if the key exists but has no associated expiry.

Starting with Redis 2.8 the return value in case of errors had changed:

* The command returns `-2` if the key doesn't exist.
* The command returns `-1` if the key exists but has no associated expiry.

See also the `PTTL` command that returns the same information with milliseconds resolution (Only available in Redis 2.6 or greater).

@return

@integer-reply: TTL in seconds, or a negative value to signal an error (see the description above).

@examples

```cli
SET mykey "Hello"
EXPIRE mykey 10
TTL mykey
```
