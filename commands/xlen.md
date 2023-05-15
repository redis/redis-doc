Returns the number of entries inside the [Redis stream](/docs/data-types/streams) at _key_.

If the specified key doesn't exist, the command returns zero, as if the stream was empty.
However, note that, unlike other Redis types, zero-length streams are possible, so you should call `TYPE` or `EXISTS` to check whether a key exists or not.

Streams aren't deleted automatically once they have no entries inside (for instance after an `XDEL` call), because the stream may have consumer groups associated with it.

@return

@integer-reply: the number of entries of the stream at _key_.

@examples

```cli
XADD mystream * item 1
XADD mystream * item 2
XADD mystream * item 3
XLEN mystream
```
