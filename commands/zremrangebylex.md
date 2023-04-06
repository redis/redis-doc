When all the members in a sorted set are inserted with the same score, to force lexicographical ordering, this command removes the number of members in the sorted set at the _key_ with a value between _min_ and _max_.

The _min_ and _max_ arguments have the same meaning as described for `ZRANGEBYLEX`.
Similarly, this command removes the same members that `ZRANGEBYLEX` would return if called with the same _min_ and _max_ arguments.

@return

@integer-reply: the number of members that were removed.

@examples

```cli
ZADD myzset 0 aaaa 0 b 0 c 0 d 0 e
ZADD myzset 0 foo 0 zap 0 zip 0 ALPHA 0 alpha
ZRANGE myzset 0 -1
ZREMRANGEBYLEX myzset [alpha [omega
ZRANGE myzset 0 -1
```
