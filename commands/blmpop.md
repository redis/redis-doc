`BLMPOP` is the blocking variant of `LMPOP`.

It pops one or more elements from the first non-empty [Redis list](/docs/data-types/lists) _key_ from the list of provided key names.

When any of the lists contains elements, this command behaves exactly like `LMPOP`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `LMPOP`.
When all lists are empty, Redis will block the connection until another client pushes to it or until the _timeout_ (a double value specifying the maximum number of seconds to block) elapses.
A _timeout_ of zero can be used to block indefinitely.

See `LMPOP` for more information.

@return

@array-reply: specifically:

* A @nil-reply when no element could be popped and the _timeout_ is reached.
* A two-element array with the first element being the name of the key from which elements were popped and the second element being an array of the popped elements.
