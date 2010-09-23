@complexity

O(log(N))+O(M) with N being the number of elements in the
sorted set and M the number of elements returned by the command, so if M is
constant (for instance you always ask for the first ten elements with LIMIT)
you can consider it O(log(N))_

Return the all the elements in the sorted set at key with a score between
_min_ and _max_ (including elements with score equal to min or max).

The elements having the same score are returned sorted lexicographically as
ASCII strings (this follows from a property of Redis sorted sets and does no
involve further computation).

Using the optional LIMIT it's possible to get only a range of the matching
elements in an SQL-alike way. Note that if _offset_ is large the commands
needs to traverse the list for _offset_ elements and this adds up to the
O(M) figure.

The **`ZCOUNT`** command is similar to **`ZRANGEBYSCORE`** but instead of returning
the actual elements in the specified interval, it just returns the number
of matching elements.

## Exclusive intervals and infinity

_min_ and _max_ can be -inf and +inf, so that you are not required to know
what's the greatest or smallest element in order to take, for instance, elements
up to a given value.

Also while the interval is for default closed (inclusive) it's possible to
specify open intervals prefixing the score with a ( character, so for instance:


``ZRANGEBYSCORE` zset (1.3 5`

Will return all the values with score ** 1.3 and = 5**, while for instance:


``ZRANGEBYSCORE` zset (5 (10`

Will return all the values with score ** 5 and 10** (5 and 10 excluded).

@return

`ZRANGEBYSCORE` returns a @multi-bulk-reply specifically a list of elements
in the specified score range.

`ZCOUNT` returns a @integer-reply specifically the number of elements matching
the specified score range.

@examples

    redis zadd zset 1 foo
    (integer) 1
    redis zadd zset 2 bar
    (integer) 1
    redis zadd zset 3 biz
    (integer) 1
    redis zadd zset 4 foz
    (integer) 1
    redis zrangebyscore zset -inf +inf
    1. foo
    2. bar
    3. biz
    4. foz
    redis zcount zset 1 2
    (integer) 2
    redis zrangebyscore zset 1 2
    1. foo
    2. bar
    redis zrangebyscore zset (1 2
    1. bar
    redis zrangebyscore zset (1 (2
    (empty list or set)



[1]: /p/redis/wiki/ReplyTypes