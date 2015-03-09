Returns all the elements in the sorted set at `key` with a score between `min`
and `max` (including elements with score equal to `min` or `max`).
The elements are considered to be ordered from low to high scores.

The elements having the same score are returned in lexicographical order (this
follows from a property of the sorted set implementation in Redis and does not
involve further computation).

The optional `LIMIT` argument can be used to only get a range of the matching
elements (similar to _SELECT LIMIT offset, count_ in SQL).
Keep in mind that if `offset` is large, the sorted set needs to be traversed for
`offset` elements before getting to the elements to return, which can add up to
O(N) time complexity.

The optional `WITHSCORES` argument makes the command return both the element and
its score, instead of the element alone.
This option is available since Redis 2.0.

## Exclusive intervals and infinity

`min` and `max` can be `-inf` and `+inf`, so that you are not required to know
the highest or lowest score in the sorted set to get all elements from or up to
a certain score.

By default, the interval specified by `min` and `max` is closed (inclusive).
It is possible to specify an open interval (exclusive) by prefixing the score
with the character `(`.
For example:

```
ZRANGEBYSCORE zset (1 5
```

Will return all elements with `1 < score <= 5` while:

```
ZRANGEBYSCORE zset (5 (10
```

Will return all the elements with `5 < score < 10` (5 and 10 excluded).

@return

@array-reply: list of elements in the specified score range (optionally
with their scores).

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZRANGEBYSCORE myzset -inf +inf
ZRANGEBYSCORE myzset 1 2
ZRANGEBYSCORE myzset (1 2
ZRANGEBYSCORE myzset (1 (2
```
