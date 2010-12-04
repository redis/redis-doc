@complexity

O(N) where N is the number of keys to retrieve


Returns the values of all specified keys. For every key that does not hold a string value
or does not exist, the special value `nil` is returned.
Because of this, the operation never fails.

@return

@multi-bulk-reply: list of values at the specified keys.

@examples

    SET foo 1000
    +OK

    SET bar 2000
    +OK

    MGET foo bar nokey
    1. 1000
    2. 2000
    3. (nil)

