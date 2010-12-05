@complexity

O(log(N)) with N being the number of elements in the sorted set.

Removes the `member` from the sorted set stored at `key`. If
`member` is not a member of the sorted set, no operation is performed.

An error is returned when `key` exists and does not hold a sorted set.

@return

@integer-reply, specifically:

* `1` if `member` was removed.
* `0` if `member` is not a member of the sorted set.

