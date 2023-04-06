Returns the number of members in the sorted set at _key_ with a score between _min_ and _max_.

The _min_ and _max_ arguments have the same semantics as described for `ZRANGEBYSCORE`.

Note: the command has a complexity of just O(log(N)) because it uses members' ranks (see `ZRANK`) to get an idea of the range.
Because of this, there is no need to do work proportional to the size of the range.

@return

@integer-reply: the number of members in the specified score range.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZCOUNT myzset -inf +inf
ZCOUNT myzset (1 3
```
