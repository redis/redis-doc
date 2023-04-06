Removes and returns up to _count_ members with the highest scores in the sorted set stored at _key_.

If unspecified, the default value for _count_ is 1.
Specifying a _count_ value that is higher than the sorted set's cardinality will not produce an
error.
When returning multiple members, the one with the highest score will be the first, followed by the members with lower scores.

@return

@array-reply: list of popped members and scores.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZPOPMAX myzset
```
