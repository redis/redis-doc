@complexity

O(N) where N is the size of the hash.

Returns all values of the hash stored at `key`.

@return

@multi-bulk-reply: list of values in the hash, or an empty list when `key` does
not exist.

@examples

    @cli
    HSET hash field1 "Hello"
    HSET hash field2 "World"
    HVALS hash

