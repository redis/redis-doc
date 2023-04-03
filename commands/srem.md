Remove the specified members from the set stored at _key_.
Specified members that are not members of the set are ignored.
If _key_ doesn't exist, it is treated as an empty set and this command returns
`0`.

An error is returned when the value stored at _key_ is not a set.

{{% alert title="Note" color="info" %}}
A Redis set always consists of one or members.
When the last member is removed, the set is automatically deleted from the database.
{{% /alert %}}

@return

@integer-reply: the number of members that were removed from the set, excluding non-existing members.

@examples

```cli
SADD myset "one"
SADD myset "two"
SADD myset "three"
SREM myset "one"
SREM myset "four"
SMEMBERS myset
```
