`BZPOPMAX` is the blocking variant of the sorted set `ZPOPMAX` primitive.

It is the blocking version because it blocks the connection when there are no
members to pop from any of the given sorted sets.
A member with the highest score is popped from the first sorted set that is
non-empty, with the given keys being checked in the order that they are given.

The _timeout_ argument is interpreted as a double value specifying the maximum
number of seconds to block. A _timeout_ of zero can be used to block indefinitely.

See the [BZPOPMIN documentation][cb] for the exact semantics, since `BZPOPMAX`
is identical to `BZPOPMIN` with the only difference being that it pops members
with the highest scores instead of popping the ones with the lowest scores.

[cb]: /commands/bzpopmin

@return

@array-reply: specifically:

* A @nil-reply when no element could be popped and the _timeout_ expired.
* A three-element multi-bulk with the first element being the name of the key
  where a member was popped, the second element is the popped member itself,
  and the third element is the score of the popped element.

@examples

```
redis> DEL zset1 zset2
(integer) 0
redis> ZADD zset1 0 a 1 b 2 c
(integer) 3
redis> BZPOPMAX zset1 zset2 0
1) "zset1"
2) "c"
3) "2"
```
