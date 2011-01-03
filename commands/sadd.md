@complexity

O(1)


Add `member` to the set stored at `key`. If `member` is already a member of
this set, no operation is performed. If `key` does not exist, a new set is
created with `member` as its sole member.

An error is returned when the value stored at `key` is not a set.

@return

@integer-reply, specifically:

* `1` if the element was added.
* `0` if the element was already a member of the set.

@examples

    @cli
    SADD myset "Hello"
    SADD myset "World"
    SADD myset "World"
    SMEMBERS myset

