This command is exactly like `XRANGE`, but with the notable difference of returning the entries in reverse order.
Also, note that the range arguments for this command are reversed, so the first argument is the _end_ ID and then the _start_ ID.
The reply will include all the elements in the range, starting from the _end_.

So for instance, to get all the elements from the higher ID to the lower ID one could use:

    XREVRANGE somestream + -

Similarly to obtain just the last element added into the stream it is enough to send:

    XREVRANGE somestream + - COUNT 1

@return

@array-reply, specifically:

The command returns the entries with IDs matching the specified range.
The returned entries are complete, which means that the ID and all the fields they are composed of are returned.
Moreover, the entries are returned with their fields and values in the same order as `XADD` added them.

@examples

```cli
XADD writers * name Virginia surname Woolf
XADD writers * name Jane surname Austen
XADD writers * name Toni surname Morrison
XADD writers * name Agatha surname Christie
XADD writers * name Ngozi surname Adichie
XLEN writers
XREVRANGE writers + - COUNT 1
```
