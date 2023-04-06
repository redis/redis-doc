Removes all members in the sorted set stored at _key_ with scores between _min_ and _max_ (inclusive).

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
