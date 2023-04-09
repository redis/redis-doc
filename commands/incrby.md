Increments the number stored as a [Redis string](/docs/data-types/strings) stored at _key_ by _increment_.
If the k_ey doesn't exist, it is set to `0` before the operation.
An error is returned if the key contains a value of the wrong type, or contains a string that can't be represented as an integer.
This operation is limited to **64-bit signed integers**.

See `INCR` for more information about increment/decrement operations.

@return

@integer-reply: the value of the _key_ after the increment

@examples

```cli
SET mykey "10"
INCRBY mykey 5
```
