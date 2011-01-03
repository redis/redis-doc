@complexity

O(1)


Returns the number of fields contained in the hash stored at `key`.

@return

@integer-reply: number of fields in the hash, or `0` when `key` does not exist.

@examples

    @cli
    HSET hash field1 "Hello"
    HSET hash field2 "World"
    HLEN hash

