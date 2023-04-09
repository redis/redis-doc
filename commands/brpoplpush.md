`BRPOPLPUSH` is the blocking variant of `RPOPLPUSH`.

It atomically returns and removes the last element (tail) of the [Redis list](/docs/data-types/lists) stored at _source_, and pushes the element at the first element (head) of the list stored at _destination_.

When _source_ contains elements, this command behaves exactly like `RPOPLPUSH`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `RPOPLPUSH`.
When _source_ is empty, Redis will block the connection until another client
pushes to it or until _timeout_ is reached.
A _timeout_ of zero can be used to block indefinitely.

See `RPOPLPUSH` for more information.

{{% alert title="Note" color="info" %}}
A Redis list always consists of at least one element.
When the last element is popped, the list is automatically deleted from the database.
{{% /alert %}}

@return

@bulk-string-reply: the element being popped from the _source_ and pushed to the _destination_.
If _timeout_ is reached, a @nil-reply is returned.

## Pattern: Reliable queue

Please see the pattern description in the `RPOPLPUSH` documentation.

## Pattern: Circular list

Please see the pattern description in the `RPOPLPUSH` documentation.
