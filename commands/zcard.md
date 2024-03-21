Returns the sorted set cardinality (number of elements) of the sorted set stored
at `key`.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZCARD myzset
```
