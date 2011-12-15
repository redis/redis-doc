@complexity

O(1).

`BRPOPLPUSH` is the blocking variant of `RPOPLPUSH`. When `source`
contains elements, this command behaves exactly like `RPOPLPUSH`.  When
`source` is empty, Redis will block the connection until another client
pushes to it or until `timeout` is reached.

`timeout` is an integer value in seconds, a value of zero can be used
to block indefinitely.

See `RPOPLPUSH` for more information.

@return

@bulk-reply: the element being popped from `source` and pushed to
`destination`. If `timeout` is reached, a @nil-reply is returned.
