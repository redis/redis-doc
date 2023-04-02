Increments the number stored at _key_ by _increment_.
If the key doesn't exist, it is set to `0` before the operation.
An error is returned if the key contains a value of the wrong type, or contains a string that can't be represented as an integer.
This operation is limited to **64-bit signed integers**.

See `INCR` for more information about increment/decrement operations.

@return

@integer-reply: the value of _key_ after the increment

@examples

```cli
SET mykey "10"
INCRBY mykey 5
```
