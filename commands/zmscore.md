Returns the scores associated with the specified members in the [Redis sorted set](/docs/data-types/sorted-sets) stored at _key_.

For every _member_ that doesn't exist in the sorted set, a `nil` value is returned.

@return

@array-reply: list of scores or @nil-reply associated with the specified _member_ values (a double-precision floating point number), represented as strings.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZMSCORE myzset "one" "two" "nofield"
```
