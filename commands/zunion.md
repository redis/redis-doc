The difference with `ZUNIONSTORE` is that the result is returned rather than 
stored.

For a description of the `WEIGHTS` and `AGGREGATE` options, see `ZUNIONSTORE`.

@return

@array-reply: the result of union (optionally with their scores, in case 
the `WITHSCORES` option is given).

@examples

```cli
ZADD zset1 1 "one"
ZADD zset1 2 "two"
ZADD zset2 1 "one"
ZADD zset2 2 "two"
ZADD zset2 3 "three"
ZUNION 2 zset1 zset2
ZUNION 2 zset1 zset2 WITHSCORES
```
