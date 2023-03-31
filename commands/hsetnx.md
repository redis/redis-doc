Sets `field` in the hash stored at `key` to `value`, only if `field` doesn't exist yet.
If `key` doesn't exist, a new key is created for the hash.
If `field` already exists, this operation has no effect.

@return

@integer-reply, specifically:

* `1` if `field` is a new field in the hash and `value` was set.
* `0` if `field` already exists in the hash and no operation was performed.

@examples

```cli
HSETNX myhash field "Hello"
HSETNX myhash field "World"
HGET myhash field
```
