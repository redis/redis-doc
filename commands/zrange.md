Returns the specified range of elements in the sorted set stored at `key`.
The elements are considered to be ordered from the lowest to the highest score.
Lexicographical order is used for elements with equal score.

As per Redis 6.2.0, this command has the capability to replace `Z[REV]RANGE[BYLEX|BYSCORE]` which are now considered deprecated.

By default the `min` and `max` arguments represent zero-based indexes, where `0`
is the first element, `1` is the next element and so on.
They can also be negative numbers indicating offsets from the end of the sorted
set, with `-1` being the last element of the sorted set, `-2` the penultimate
element and so on. in that case
`min` and `max` are **inclusive ranges**, so for example `ZRANGE myzset 0 1`
will return both the first and the second element of the sorted set.

Out of range indexes will not produce an error.
If `min` is larger than the largest index in the sorted set, or `min > max`, an empty list is returned.
If `max` is larger than the end of the sorted set Redis will treat it like it
is the last element of the sorted set.

If a `BYSCORE` argument is given the command behaves like `ZRANGEBYSCORE`, see its documentation for details.
If a `BYLEX` argument is given the command behaves like `ZRANGEBYLEX`, see its documentation for details.

The optional `REV` argument can be used to have the elements ordered from the highest to the lowest score.
Descending lexicographical order is used for elements with equal score.

The optional `LIMIT` argument can be used to only get a range of the matching
elements (similar to _SELECT LIMIT offset, count_ in SQL). A negative `count`
returns all elements from the `offset`.
Keep in mind that if `offset` is large, the sorted set needs to be traversed for
`offset` elements before getting to the elements to return, which can add up to
O(N) time complexity.

It is possible to pass the `WITHSCORES` option in order to return the scores of
the elements together with the elements.
The returned list will contain `value1,score1,...,valueN,scoreN` instead of
`value1,...,valueN`.
Client libraries are free to return a more appropriate data type (suggestion: an
array with (value, score) arrays/tuples).

@return

@array-reply: list of elements in the specified range (optionally with
their scores, in case the `WITHSCORES` option is given).

@history

* `>= 6.2`: Added the `REV`, `BYSCORE`, `BYLEX` and `LIMIT` options.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZRANGE myzset 0 -1
ZRANGE myzset 2 3
ZRANGE myzset -2 -1
```

The following example using `WITHSCORES` shows how the command returns always an array, but this time, populated with *element_1*, *score_1*, *element_2*, *score_2*, ..., *element_N*, *score_N*.

```cli
ZRANGE myzset 0 1 WITHSCORES
```
