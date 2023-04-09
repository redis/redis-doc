Returns the cardinality (number of members) of the [Redis sorted set](/docs/data-types/sorted-sets) stored at _key_.

@return

@integer-reply: the cardinality (number of members) of the sorted set, or `0` if the _key_ doesn't exist.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZCARD myzset
```
