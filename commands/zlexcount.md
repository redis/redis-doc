When all the members in a sorted set are inserted with the same score, to force lexicographical ordering, this command returns the number of members in the sorted set at the _key_ with a value between _min_ and _max_.

The _min_ and _max_ arguments have the same meaning as described for `ZRANGEBYLEX`.

Note: the command has a complexity of just O(log(N)) because it uses members' ranks (see `ZRANK`) to get an idea of the range.
Because of this, there is no need to do work proportional to the size of the range.

@return

@integer-reply: the number of members in the specified score range.

@examples

```cli
ZADD myzset 0 a 0 b 0 c 0 d 0 e
ZADD myzset 0 f 0 g
ZLEXCOUNT myzset - +
ZLEXCOUNT myzset [b [f
```
