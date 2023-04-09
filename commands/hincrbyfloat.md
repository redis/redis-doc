Increment the floating-point number value of the specified _field_ of a [Redis hash](/docs/data-types/hashes) stored at the _key_ by the specified _increment_.
Use a negative increment value to **decrement** the hash field's value.
If the field doesn't exist, it is set to `0` before the operation.
An error is returned if the field's value or increment aren't string representations of a floating-point number.

The behavior of this command is identical to the one of the `INCRBYFLOAT` command.
Please refer to the documentation of `INCRBYFLOAT` for further information.

@return

@bulk-string-reply: the value of the _field_ after the increment.

@examples

```cli
HSET mykey field 10.50
HINCRBYFLOAT mykey field 0.1
HINCRBYFLOAT mykey field -5
HSET mykey field 5.0e3
HINCRBYFLOAT mykey field 2.0e2
```

## Implementation details

The command is always propagated in the replication link and the Append Only File as an `HSET` operation so that differences in the underlying floating point math implementation won't be sources of inconsistency.
