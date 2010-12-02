@complexity

O(log(N))+O(M) with N being the number of elements in the
sorted set and M the number of elements returned by the command, so if M is
constant (for instance you always ask for the first ten elements with `LIMIT`)
you can consider it O(log(N)).

Returns all the elements in the sorted set at `key` with a score between
`min` and `max` (including elements with score equal to `min` or `max`).

The elements having the same score are returned sorted lexicographically as
ASCII strings (this follows from a property of the sorted set implementation in
Redis and does not involve further computation).

The optional `LIMIT` argument can be used to only get a range of the matching
elements (similar to _SELECT LIMIT offset, count_ in SQL). Keep in mind that if
`offset` is large, the sorted set needs to be traversed for `offset` elements
before getting to the elements to return, which can add up to O(M) time
complexity.

The optional `WITHSCORES` argument makes the command return both the element and
its score, instead of the element alone. This option is available since Redis
2.0.

## Exclusive intervals and infinity

`min` and `max` can be `-inf` and `+inf`, so that you are not required to know
what's the greatest or smallest element in order to take, for instance, elements
up to a given value.

Also while the interval is for default closed (inclusive) it's possible to
specify open intervals prefixing the score with a `(` character, so for instance:

    ZRANGEBYSCORE zset (1 5

Will return all the elements with _1 < `score` <= 5_ while:

    ZRANGEBYSCORE zset (5 (10

Will return all the elements with _5 < `score` < 10_ (5 and 10 excluded).

@return

@multi-bulk-reply: a list of elements in the specified score range.

@examples

    ZADD zset 1 foo
    (integer) 1
    ZADD zset 2 bar
    (integer) 1
    ZADD zset 3 biz
    (integer) 1
    ZADD zset 4 foz
    (integer) 1

    ZRANGEBYSCORE zset -inf +inf
    1. foo
    2. bar
    3. biz
    4. foz

    ZCOUNT zset 1 2
    (integer) 2

    ZRANGEBYSCORE zset 1 2
    1. foo
    2. bar

    ZRANGEBYSCORE zset (1 2
    1. bar

    ZRANGEBYSCORE zset (1 (2
    (empty list or set)

