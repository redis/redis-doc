Sets the specified fields to their respective values in the hash stored at `key`.

This command overwrites any specified fields already existing in the hash. If `key` does not exist, a new key holding a hash is created.

@return

@integer-reply: The number of fields that were added.

@examples

```cli
HSET myhash field1 "Hello"
HGET myhash field1
HMSET myhash field2 "Hi" field3 "World"
HGET myhash field2
HGET myhash field3
HGETALL myhash
```
