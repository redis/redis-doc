@complexity

O(1)


Increments the number stored at `key` by one.
If the key does not exist, it is set to `0` before performing the operation. An
error is returned if the key contains a value of the wrong type or contains a
string that is not representable as integer. This operation is limited to 64
bit signed integers.

**Note**: this is a string operation because Redis does not have a dedicated
integer type. The the string stored at the key is interpreted as a base-10 **64
bit signed integer** to execute the operation.

Redis stores integers in their integer representation, so for string values
that actually hold an integer, there is no overhead for storing the
string representation of the integer.

@return

@integer-reply: the value of `key` after the increment

@examples

    @cli
    SET mykey "10"
    INCR mykey
    GET mykey

