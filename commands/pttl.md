@complexity

O(1)

Like `TTL` this command returns the remaining time to live of a key that has an
expire set, with the sole difference that `TTL` returns the amount of remaining
time in seconds while `PTTL` returns it in milliseconds.

@return

@integer-reply: Time to live in milliseconds or `-1` when `key` does not exist
or does not have a timeout.

@examples

```cli
SET mykey "Hello"
EXPIRE mykey 1
PTTL mykey
```
