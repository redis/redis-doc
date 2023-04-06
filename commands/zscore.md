Returns the score of a _member_ in the sorted set at _key_.

If the _member_ doesn't belong to the sorted set, or the _key_ doesn't exist, `nil` is returned.

@return

@bulk-string-reply: the score of the _member_ (a double-precision floating point number), represented as a string.

@examples

```cli
ZADD myzset 1 "one"
ZSCORE myzset "one"
```
