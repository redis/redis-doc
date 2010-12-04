@complexity

O(N) where N is the number of keys to set


Sets the given keys to their respective values. `MSET` replaces existing values
with new values, just as regular `SET`.  See `MSETNX` if you don't want to
overwrite existing values.

`MSET` is atomic, so all given keys are set at once. It is not possible for
clients to see that some of the keys were updated while others are unchanged.

@return

@status-reply: always `OK` since `MSET` can't fail.

