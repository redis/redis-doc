Fields that don't exist within this hash are ignored.
If _key_ doesn't exist, it is treated as an empty hash and this command returns
`0`.

{{% alert title="Note" color="info" %}}
A Redis hash always consists of one or more fields and their respective values.
When the last field is deleted, the hash is automatically deleted from the database.
{{% /alert  %}}

@return

@integer-reply: the number of fields that were removed from the hash, excluding any specified but non-existing fields.

@examples

```cli
HSET myhash field1 "foo"
HDEL myhash field1
HDEL myhash field2
```
