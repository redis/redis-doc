@complexity

O(1)


Add `member` to the set stored at `key`. If `member` is already a member of
this set, no operation is performed. If `key` does not exist, a new set is
created with `member` as its sole member.

An error is returned when the value stored at `key` is not a set.

@return

@integer-reply: the number of elements actually added to the set.

History
---

Up until Redis 2.3, `SADD` accepted a single `member`.

@examples

    @cli
    SADD myset "Hello"
    SADD myset "World"
    SADD myset "World"
    SMEMBERS myset

