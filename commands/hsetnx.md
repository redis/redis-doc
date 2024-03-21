Sets `field` in the hash stored at `key` to `value`, only if `field` does not
yet exist.
If `key` does not exist, a new key holding a hash is created.
If `field` already exists, this operation has no effect.

@examples

```cli
HSETNX myhash field "Hello"
HSETNX myhash field "World"
HGET myhash field
```
