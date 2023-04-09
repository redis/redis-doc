Sets the specified fields to their respective values in the [Redis hash](/docs/data-types/hashes) stored at the _key_.

The command overwrites all specified fields that already exist in the hash.
If the _key_ doesn't exist, a new key is created for the hash.

@return

@simple-string-reply: `OK`.

@examples

```cli
HMSET myhash field1 "Hello" field2 "World"
HGET myhash field1
HGET myhash field2
```
