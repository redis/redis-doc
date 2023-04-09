Removes the specified members from the [Redis sorted set](/docs/data-types/sorted-sets) stored at _key_.

Members that don't exist are silently ignored.

An error is returned when _key_ exists and doesn't store a sorted set.

{{% alert title="Note" color="info" %}}
A Redis sorted set always consists of at least one member.
When the last member is removed, the sorted set is automatically deleted from the database.
{{% /alert %}}

@return

@integer-reply, specifically:

* The number of members removed from the sorted set, excluding non-existing members.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZREM myzset "two"
ZRANGE myzset 0 -1 WITHSCORES
```
