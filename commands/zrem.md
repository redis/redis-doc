Removes the specified members from the sorted set stored at _key_.
Non-existing members are ignored.

An error is returned when _key_ exists and doesn't store a sorted set.

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
