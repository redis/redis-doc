Removes all elements in the sorted set stored at _key_ with ranks between _start_ and _stop_.

Both _start_ and _stop_ are 0-based indexes, with `0` being the member with the lowest score.
These indexes can be negative numbers, where they indicate offsets starting at the member with the highest score.
For example, `-1` is the member with the highest score, `-2` is the member with the second highest score and so forth.

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
ZREMRANGEBYRANK myzset 0 1
ZRANGE myzset 0 -1 WITHSCORES
```
