Sets the specified fields to their respective values in the hash stored at `key`.
The command overwrites all specified fields that already exist in the hash.
If `key` doesn't exist, a new key is created for the hash.

@return

@simple-string-reply

@examples

```cli
HMSET myhash field1 "Hello" field2 "World"
HGET myhash field1
HGET myhash field2
```
