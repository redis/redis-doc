`BZPOPMIN` is the blocking variant of the sorted set `ZPOPMIN` primitive.

It is the blocking version because it blocks the connection when there are no
members to pop from any of the given sorted sets.
A member with the lowest score is popped from first sorted set that is
non-empty, with the given keys being checked in the order that they are given.

The `timeout` argument is interpreted as a double value specifying the maximum
number of seconds to block. A timeout of zero can be used to block indefinitely.

See the [BLPOP documentation][cl] for the exact semantics, since `BZPOPMIN` is
identical to `BLPOP` with the only difference being the data structure being
popped from.

[cl]: /commands/blpop

@examples

```
redis> DEL zset1 zset2
(integer) 0
redis> ZADD zset1 0 a 1 b 2 c
(integer) 3
redis> BZPOPMIN zset1 zset2 0
1) "zset1"
2) "a"
3) "0"
```
