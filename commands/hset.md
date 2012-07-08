Sets `field` in the hash stored at `key` to `value`.
If `key` does not exist, a new key holding a hash is created.
If `field` already exists in the hash, it is overwritten.

@return

@integer-reply, specifically:

* `1` if `field` is a new field in the hash and `value` was set.
* `0` if `field` already exists in the hash and the value was updated.

@examples

```cli
HSET myhash field1 "Hello"
HGET myhash field1
```
