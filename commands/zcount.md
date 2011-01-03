@complexity

O(log(N)+M) with N being the number of elements in the
sorted set and M being the number of elements between `min` and `max`.

Returns the number of elements in the sorted set at `key` with
a score between `min` and `max`.

The `min` and `max` arguments have the same semantic as described
for `ZRANGEBYSCORE`.

@return

@integer-reply: the number of elements in the specified score range.

@examples

    @cli
    ZADD myzset 1 "one"
    ZADD myzset 2 "two"
    ZADD myzset 3 "three"
    ZCOUNT myzset -inf +inf
    ZCOUNT myzset (1 3

