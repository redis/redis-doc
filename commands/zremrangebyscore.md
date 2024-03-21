Removes all elements in the sorted set stored at `key` with a score between
`min` and `max` (inclusive).

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZREMRANGEBYSCORE myzset -inf (2
ZRANGE myzset 0 -1 WITHSCORES
```
