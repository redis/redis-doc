Returns the bit value at *offset* in the string value stored at *key*.

When *offset* is beyond the string length, the string is assumed to be a
contiguous space with 0 bits. When *key* does not exist it is assumed to be an
empty string, so *offset* is always out of range and the value is also assumed
to be a contiguous space with 0 bits.

@return

@integer-reply: the bit value stored at *offset*.

@examples

    @cli
    SETBIT mykey 7 1
    GETBIT mykey 0
    GETBIT mykey 7
    GETBIT mykey 100
