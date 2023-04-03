In the reply, every field name is followed by its value, so the length of the reply is twice the size of the hash.

{{% alert title="Warning" color="warning" %}}
This command requires space and time that are proportional to the hash's number of fields.
Given this command's complexity, you should use caution when calling it in production.
Prefer using `HSCAN` for iterating over hashes with a large number of fields.
{{% /alert %}}

@return

@array-reply: list of fields and their values stored in the hash, or an
empty list when _key_ doesn't exist.

@examples

```cli
HSET myhash field1 "Hello"
HSET myhash field2 "World"
HGETALL myhash
```
