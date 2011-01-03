@complexity

O(1)


Remove `member` from the set stored at `key`. If `member` is not a member of
this set, no operation is performed.

An error is returned when the value stored at `key` is not a set.

@return

@integer-reply, specifically:

* `1` if the element was removed.
* `0` if the element was not a member of the set.

@examples

    @cli
    SADD myset "one"
    SADD myset "two"
    SADD myset "three"
    SREM myset "one"
    SREM myset "four"
    SMEMBERS myset

