Removes all members in the [Redis sorted set](/docs/data-types/sorted-sets) stored at _key_ with scores between _min_ and _max_ (inclusive).

{{% alert title="Note" color="info" %}}
A Redis sorted set always consists of at least one member.
When the last member is removed, the sorted set is automatically deleted from the database.
{{% /alert %}}

@return

@integer-reply: the number of members removed.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZREMRANGEBYSCORE myzset -inf (2
ZRANGE myzset 0 -1 WITHSCORES
```
