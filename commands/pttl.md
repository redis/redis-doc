Like `TTL` this command returns the remaining time-to-live (TTL) of a _key_ that has an expiration time set, with the sole difference that `TTL` returns the amount of remaining time in seconds while `PTTL` returns it in milliseconds.

@return

@integer-reply: TTL in milliseconds, or a negative value to signal an error (see the description below).

In Redis 2.6 or older, the command returns `-1` if the _key_ doesn't exist or if the _key_ exists but has no associated TTL.

Starting with Redis 2.8 the return value in case of errors changed:

* The command returns `-2` if the key does not exist.
* The command returns `-1` if the key exists but has no associated expiry.

@examples

```cli
SET mykey "Hello"
EXPIRE mykey 1
PTTL mykey
```
