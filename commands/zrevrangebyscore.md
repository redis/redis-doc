Returns all the elements in the sorted set at _key_ with a score between _max_ and _min_ (including elements with scores equal to _max_ or _min_).
Contrary to the default ordering of sorted sets, this command orders the members by theirs scores in descending order.

Members that have the same scores are returned in reverse lexicographical order.

Apart from the reversed ordering, `ZREVRANGEBYSCORE` is similar to `ZRANGEBYSCORE`.

@return

@array-reply: list of members in the specified score range (optionally with their scores).

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZREVRANGEBYSCORE myzset +inf -inf
ZREVRANGEBYSCORE myzset 2 1
ZREVRANGEBYSCORE myzset 2 (1
ZREVRANGEBYSCORE myzset (2 (1
```
