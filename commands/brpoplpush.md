`BRPOPLPUSH` is the blocking variant of `RPOPLPUSH`.
When `source` contains elements, this command behaves exactly like `RPOPLPUSH`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `RPOPLPUSH`.
When `source` is empty, Redis will block the connection until another client
pushes to it or until `timeout` is reached.
A `timeout` of zero can be used to block indefinitely.

See `RPOPLPUSH` for more information.

## Pattern: Reliable queue

Please see the pattern description in the `RPOPLPUSH` documentation.

## Pattern: Circular list

Please see the pattern description in the `RPOPLPUSH` documentation.
