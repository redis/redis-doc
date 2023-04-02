Sets the specified fields to their respective values in the hash stored at _key_.

The command overwrites all specified fields that already exist in the hash.
If the _key_ doesn't exist, a new key is created for the hash.

@return

@integer-reply: The number of fields that were added.

@examples

```cli
HSET myhash field1 "Hello"
HGET myhash field1
HSET myhash field2 "Hi" field3 "World"
HGET myhash field2
HGET myhash field3
HGETALL myhash
```
