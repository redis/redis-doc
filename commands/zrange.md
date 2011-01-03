@complexity

O(log(N)+M) with N being the number of elements in the sorted set and M the
number of elements returned.

Returns the specified range of elements in the sorted set stored at `key`. The
elements are considered to be ordered from the lowest to the highest score.

See `ZREVRANGE` when you need the elements ordered from highest to lowest
score.

Both `start` and `stop` are zero-based indexes, where `0` is the first element,
`1` is the next element and so on. They can also be negative numbers indicating
offsets from the end of the sorted set, with `-1` being the last element of the
sorted set, `-2` the penultimate element and so on.

Out of range indexes will not produce an error. If `start` is larger than the
largest index in the sorted set, or `start > stop`, an empty list is returned.
If `stop` is larger than the end of the sorted set Redis will treat it like it
is the last element of the sorted set.

It is possible to pass the `WITHSCORES` option in order to return the scores of
the elements together with the elements.  The returned list will contain
`value1,score1,...,valueN,scoreN` instead of `value1,...,valueN`.  Client
libraries are free to return a more appropriate data type (suggestion: an array
with (value, score) arrays/tuples).

@return

@multi-bulk-reply: list of elements in the specified range (optionally with
their scores).

@examples

    @cli
    ZADD myzset 1 "one"
    ZADD myzset 2 "two"
    ZADD myzset 3 "three"
    ZRANGE myzset 0 -1
    ZRANGE myzset 2 3
    ZRANGE myzset -2 -1

