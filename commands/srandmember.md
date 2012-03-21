Return a random element from the set value stored at `key`.

This operation is similar to `SPOP`, however while `SPOP` also removes the
randomly selected element from the set, `SRANDMEMBER` will just return a random
element without altering the original set in any way.

@return

@bulk-reply: the randomly selected element, or `nil` when `key` does not exist.

@examples

    @cli
    SADD myset "one"
    SADD myset "two"
    SADD myset "three"
    SRANDMEMBER myset

