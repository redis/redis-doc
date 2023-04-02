Increments the number stored at _field_ in the hash stored at _key_ by _increment_.
If _key_ doesn't exist, a new key holding a hash is created.
If _field_ doesn't exist, the value is set to `0` before the operation is
performed.

The range of values supported by `HINCRBY` is limited to 64-bit signed integers.

@return

@integer-reply: the value at _field_ after the increment operation.

@examples

Since the _increment_ argument is signed, both increment and decrement operations can be performed:

```cli
HSET myhash field 5
HINCRBY myhash field 1
HINCRBY myhash field -1
HINCRBY myhash field -10
```
