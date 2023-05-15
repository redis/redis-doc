Returns the number of fields contained in the [Redis hash](/docs/data-types/hashes) stored at _key_.

@return

@integer-reply: number of fields in the hash, or `0` when _key_ doesn't exist.

@examples

```cli
HSET myhash field1 "Hello"
HSET myhash field2 "World"
HLEN myhash
```
