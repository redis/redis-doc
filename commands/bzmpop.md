`BZMPOP` is the blocking variant of `ZMPOP`.

It pops one or more members from the first non-empty [Redis sorted set](/docs/data-types/sorted-sets) in the provided list of _key_ names.

When any of the sorted sets contain elements, this command behaves exactly like `ZMPOP`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `ZMPOP`.
When all sorted sets are empty, Redis will block the connection until another client adds members to one of the keys or until the _timeout_ (a double value specifying the maximum number of seconds to block) elapses.
A _timeout_ of zero can be used to block indefinitely.

See `ZMPOP` for more information.

@return

@array-reply: specifically:

* A @nil-reply when no element could be popped.
* A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.

