Returns all field names in the hash stored at `key`.

{{% alert title="Warning" color="warning" %}}
This command requires space and time that are proportional to the hash's number of fields.
Given this command's complexity, you should use caution when calling it in production.
Prefer using `HSCAN` for iterating over hashes with a large number of fields.
{{% /alert  %}}

@return

@array-reply: list of fields in the hash, or an empty list when `key` does
not exist.

@examples

```cli
HSET myhash field1 "Hello"
HSET myhash field2 "World"
HKEYS myhash
```
