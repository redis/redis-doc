@complexity

O(N*M) worst case where N is the cardinality of the smallest set and M is the
number of sets.

This command is equal to `SINTER`, but instead of returning the resulting set,
it is stored in `destination`.

If `destination` already exists, it is overwritten.

@return

@integer-reply: the number of elements in the resulting set.
