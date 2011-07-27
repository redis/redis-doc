@complexity

O(1)


Remove `member` from the set stored at `key`. If `member` is not a member of
this set, no operation is performed.

An error is returned when the value stored at `key` is not a set.

@return

@integer-reply: the number of members that were removed from the set.

@history

* `>= 2.4`: Accepts multiple `member` arguments.

@examples

    @cli
    SADD myset "one"
    SADD myset "two"
    SADD myset "three"
    SREM myset "one"
    SREM myset "four"
    SMEMBERS myset

