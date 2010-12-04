@complexity

O(1)


Increments the number stored at `key` by `increment`.
If the key does not exist or contains a value of the wrong type, it is set to
`0` before performing the operation. This operation is limited to 64 bit signed
integers.

See `INCR` for extra information on increment/decrement operations.

@return

@integer-reply: the value of `key` after the increment

