@complexity

O(log(N)) where N is the number of elements in the sorted set.

Adds the `member` with the specified `score` to the sorted set stored at `key`.
If `member` is already a member of the sorted set, the score is updated and the
element reinserted at the right position to ensure the correct ordering.  If
`key` does not exist, a new sorted set with the specified `member` as sole
member is created.  If the key exists but does not hold a sorted set, an error
is returned.

The `score` value should be the string representation of a numeric value, and
accepts double precision floating point numbers.

For an introduction to sorted sets, see the data types page on [sorted
sets](/topics/data-types#sorted-sets).

@return

@integer-reply, specifically:

* `1` if the element was added.
* `0` if the element was already a member of the sorted set and the score was
  updated.

