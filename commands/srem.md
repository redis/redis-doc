@complexity

O(N) where N is the number of members to be removed.


Remove the specified members from the set stored at `key`. Specified members
that are not a member of this set are ignored.  If `key` does not exist, it is
treated as an empty set and this command returns `0`.

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

