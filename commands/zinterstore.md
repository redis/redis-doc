Computes the intersection of exactly _numkeys_ sorted sets given by the specified keys, and stores the result in the _destination_.
It is mandatory to provide the number of input keys (_numkeys_) before any other arguments.

By default, the resulting score of a member is the sum of its scores in the sorted sets where it exists.
Because intersection requires a member to belong to all sorted sets, this results in the score of every element in the resulting sorted set being equal to the number of input sorted sets.

For a description of the `WEIGHTS` and `AGGREGATE` options, see `ZUNIONSTORE`.

If the _destination_ already exists, it is overwritten.

@return

@integer-reply: the number of members in the resulting sorted set at the _destination_.

@examples

```cli
ZADD zset1 1 "one"
ZADD zset1 2 "two"
ZADD zset2 1 "one"
ZADD zset2 2 "two"
ZADD zset2 3 "three"
ZINTERSTORE out 2 zset1 zset2 WEIGHTS 2 3
ZRANGE out 0 -1 WITHSCORES
```
