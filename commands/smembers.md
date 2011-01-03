@complexity

O(N) where N is the set cardinality.

Returns all the members of the set value stored at `key`.

This has the same effect as running `SINTER` with one argument `key`.

@return

@multi-bulk-reply: all elements of the set.

@examples

    @cli
    SADD myset "Hello"
    SADD myset "World"
    SMEMBERS myset

