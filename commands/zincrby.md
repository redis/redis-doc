Increments the score of the _member_ in the [Redis sorted set](/docs/data-types/sorted-sets) stored at the _key_ by _increment_.

If the _member_ doesn't exist in the sorted set, it is added with the _increment_ as its score (as if its previous score was `0.0`).
If _key_ doesn't exist, a new sorted set is created with the specified _member_ as its sole member.

An error is returned when the _key_ exists but doesn't store a sorted set.

The _score_ should be the string representation of a numeric value and accepts double-precision floating point numbers.
It is possible to provide a negative value to decrement the score.

@return

@bulk-string-reply: the new score of the _member_ (a double-precision floating point number), represented as a string.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZINCRBY myzset 2 "one"
ZRANGE myzset 0 -1 WITHSCORES
```
