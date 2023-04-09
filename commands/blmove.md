`BLMOVE` is the blocking variant of `LMOVE`.
It atomically returns and removes the first/last element (head/tail depending on the _wherefrom_ argument) of the [Redis list](/docs/data-types/lists) stored at _source_, and pushes the element at the first/last element (head/tail depending on the _whereto_ argument) of the list stored at _destination_.

When the _source_ contains elements, this command behaves exactly like `LMOVE`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `LMOVE`.
When the _source_ is empty, Redis will block the connection until another client pushes to it or until _timeout_ (a double value specifying the maximum number of seconds to block) is reached.
A _timeout_ of zero can be used to block indefinitely.

This command comes in place of the now deprecated `BRPOPLPUSH`. Doing
`BLMOVE RIGHT LEFT` is equivalent.

See `LMOVE` for more information.

@return

@bulk-string-reply: the element being popped from the _source_ and pushed to the _destination_.
If the _timeout_ is reached, a @nil-reply is returned.

## Pattern: Reliable queue

Please see the pattern description in the `LMOVE` documentation.

## Pattern: Circular list

Please see the pattern description in the `LMOVE` documentation.
