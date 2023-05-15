When all the members in a [Redis sorted set](/docs/data-types/sorted-sets) are inserted with the same score, to force lexicographical ordering, this command returns the number of members in the sorted set at the _key_ with a value between _max_ and _min_.

Apart from the reversed ordering, `ZREVRANGEBYLEX` is similar to `ZRANGEBYLEX`.

@return

@array-reply: list of members in the specified score range.

@examples

```cli
ZADD myzset 0 a 0 b 0 c 0 d 0 e 0 f 0 g
ZREVRANGEBYLEX myzset [c -
ZREVRANGEBYLEX myzset (c -
ZREVRANGEBYLEX myzset (g [aaa
```
