@complexity

O(log(N)+M) with N being the number of elements in the sorted set and M the
number of elements removed by the operation.

Removes all elements in the sorted set stored at `key` with a score between
`min` and `max` (inclusive).

Since version 2.1.6, `min` and `max` can be exclusive, following the syntax of
`ZRANGEBYSCORE`.

@return

@integer-reply: the number of elements removed.

