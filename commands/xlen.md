Returns the number of entries inside a stream. If the specified key does not
exist the command returns zero, like if the stream was empty.
However note that unlikely other Redis types, zero-length streams are
possible, so you should call `TYPE` or `EXISTS` in order to really check if
a key exists or not.

Streams are not auto deleted once they have no entries inside (for instance
after an `XDEL` call), because the stream could have consumer groups
associated with it.

@return

@integer-reply: the number of entries of the stream at `key`.

@examples

```cli
XADD mystream * item 1
XADD mystream * item 2
XADD mystream * item 3
XLEN mystream
```
