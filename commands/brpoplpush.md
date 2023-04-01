`BRPOPLPUSH` is the blocking variant of `RPOPLPUSH`.
When _source_ contains elements, this command behaves exactly like `RPOPLPUSH`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `RPOPLPUSH`.
When _source_ is empty, Redis will block the connection until another client
pushes to it or until _timeout_ is reached.
A _timeout_ of zero can be used to block indefinitely.

See `RPOPLPUSH` for more information.

@return

@bulk-string-reply: the element being popped from the _source_ and pushed to the _destination_.
If _timeout_ is reached, a @nil-reply is returned.

## Pattern: Reliable queue

Please see the pattern description in the `RPOPLPUSH` documentation.

## Pattern: Circular list

Please see the pattern description in the `RPOPLPUSH` documentation.
