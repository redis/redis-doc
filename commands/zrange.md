Returns the specified range of members in the sorted set stored at _key_.

`ZRANGE` can perform different types of range queries: by index (rank), by the score, or by lexicographical order.

Starting with Redis 6.2.0, this command can replace the following commands: `ZREVRANGE`, `ZRANGEBYSCORE`, `ZREVRANGEBYSCORE`, `ZRANGEBYLEX` and `ZREVRANGEBYLEX`.

## Common behavior and options

The order of members is from the lowest to the highest score.
Members with the same score are ordered lexicographically.

The optional `REV` argument reverses the ordering, so members are ordered from highest to lowest score, and score ties are resolved by reverse lexicographical ordering.

The optional `LIMIT` argument can be used to obtain a sub-range from the matching members (similar to _SELECT LIMIT offset, count_ in SQL).
A negative _count_ returns all members from the _offset_.
Keep in mind that if _offset_ is large, the sorted set needs to be traversed for _offset_ members before getting to the members to return, which can add up to O(N) time complexity.

The optional `WITHSCORES` argument supplements the command's reply with the scores of members returned.
The returned list contains `value1,score1,...,valueN,scoreN` instead of `value1,...,valueN`.
Client libraries are free to return a more appropriate data type (suggestion: an array with (value, score) arrays/tuples).

## Index ranges

By default, the command performs an index range query.
The _start_ and _stop_ arguments represent zero-based indexes, where `0` is the first member, `1` is the next member, and so on.
These arguments specify an **inclusive range**, so for example, `ZRANGE myzset 0 1` will return both the first and the second member of the sorted set.

The indexes can also be negative numbers indicating offsets from the end of the sorted set, with `-1` being the last member of the sorted set, `-2` the penultimate member, and so on.

Out-of-range indexes don't produce an error.

If _start_ is greater than either the end index of the sorted set or _stop_, an empty list is returned.

If _stop_ is greater than the end index of the sorted set, Redis will use the last member of the sorted set.

## Score ranges

When the `BYSCORE` option is provided, the command behaves like `ZRANGEBYSCORE` and returns the range of members from the sorted set having scores equal to or between _start_ and _stop_.

_start_ and _stop_ can be `-inf` and `+inf`, denoting the negative and positive infinities, respectively.
This means that you are not required to know the highest or lowest score in the sorted set to get all members from or up to a certain score.

By default, the score intervals specified by _start_ and _stop_ are closed (inclusive).
It is possible to specify an open interval (exclusive) by prefixing the score with the left parenthesis character (`(`).

For example:

```
ZRANGE zset (1 5 BYSCORE
```

Will return all members with `1 < score <= 5` while:

```
ZRANGE zset (5 (10 BYSCORE
```

Will return all the members with `5 < score < 10` (5 and 10 excluded).

## Reverse ranges

Using the `REV` option reverses the sorted set, with index 0 as the member with the highest score.

By default, _start_ must be less than or equal to _stop_ to return anything.
However, if the `BYSCORE`, or `BYLEX` options are selected, the _start_ is the highest score to consider, and _stop_ is the lowest score to consider, therefore _start_ must be greater than or equal to _stop_ to return anything.

For example:

```
ZRANGE zset 5 10 REV
```

Will return the members between index 5 and 10 in the reversed index.

```
ZRANGE zset 10 5 REV BYSCORE
```

Will return all members with scores less than 10 and greater than 5.

## Lexicographical ranges

When the `BYLEX` option is used, the command behaves like `ZRANGEBYLEX` and returns the range of members from the sorted set between the _start_ and _stop_ lexicographical closed range intervals.

Note that lexicographical ordering relies on all members having the same score.
The reply is unspecified when the members have different scores.

Valid _start_ and _stop_ must start with `(` or `[`, to specify whether the range interval is exclusive or inclusive, respectively.

The special values of `+` or `-` for _start_ and _stop_ mean positive and negative infinite strings, respectively, so for instance the command `ZRANGE myzset - + BYLEX` is guaranteed to return all the members in the sorted set, providing that all the members have the same score.

The `REV` options reverses the order of the _start_ and _stop_ members, where _start_ must be lexicographically greater than _stop_ to produce a non-empty result.

### Lexicographical comparison of strings

Strings are compared as a binary array of bytes.
Because of how the ASCII character set is specified, this means that usually this also has the effect of comparing normal ASCII characters in an obvious dictionary way.
However, this is not true if non-plain ASCII strings are used (for example, utf8 strings).

However, the user can apply a transformation to the encoded string so that the first part of the member inserted in the sorted set will compare as the user requires for the specific application. 
For example, if I want to add strings that will be compared in a case-insensitive way, but I still
want to retrieve the real case when querying, I can add strings in the following way:

    ZADD autocomplete 0 foo:Foo 0 bar:BAR 0 zap:zap

Because of the first *normalized* part in every member (before the colon character), we are forcing a given comparison. However, after the range is queried using `ZRANGE ... BYLEX`, the application can display to the user the second part of the string, after the colon.

The binary nature of the comparison allows for using sorted sets as a general-purpose index, for example, the first part of the member can be a 64-bit big-endian number.
Since big-endian numbers have the most significant bytes in the initial positions, the binary comparison will match the numerical comparison of the numbers. This can be used to implement range queries on 64-bit values. 
As in the example below, after the first 8 bytes, we can store the value of the member we are indexing.

@return

@array-reply: list of members in the specified range (optionally with their scores, in case the `WITHSCORES` option is given).

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZRANGE myzset 0 -1
ZRANGE myzset 2 3
ZRANGE myzset -2 -1
```

The following example using `WITHSCORES` shows how the command returns always an array, but this time, populated with *member_1*, *score_1*, *member_2*, *score_2*, ..., *member_N*, *score_N*.

```cli
ZRANGE myzset 0 1 WITHSCORES
```

This example shows how to query the sorted set by score, excluding the value `1` and up to infinity, returning only the second member of the result:

```cli
ZRANGE myzset (1 +inf BYSCORE LIMIT 1 1
```
