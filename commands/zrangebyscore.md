@complexity

O(log(N))+O(M) with N being the number of elements in the
sorted set and M the number of elements returned by the command, so if M is
constant (for instance you always ask for the first ten elements with `LIMIT`)
you can consider it O(log(N)).

Return the all the elements in the sorted set at key with a score between
`min` and `max` (including elements with score equal to `min` or `max`).

The elements having the same score are returned sorted lexicographically as
ASCII strings (this follows from a property of Redis sorted sets and does not
involve further computation).

Using the optional `LIMIT` it's possible to get only a range of the matching
elements in an SQL-alike way. Note that if `offset` is large the commands
needs to traverse the list for `offset` elements and this adds up to the
O(M) figure.

## Exclusive intervals and infinity

`min` and `max` can be `-inf` and `+inf`, so that you are not required to know
what's the greatest or smallest element in order to take, for instance, elements
up to a given value.

Also while the interval is for default closed (inclusive) it's possible to
specify open intervals prefixing the score with a `(` character, so for instance:

    ZRANGEBYSCORE zset (1.3 5

will return all the values with score ** 1.3 and = 5**, while for instance:

    ZRANGEBYSCORE zset (5 (10

Will return all the values with score ** 5 and 10** (5 and 10 excluded).

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
