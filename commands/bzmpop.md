`BZMPOP` is the blocking variant of `ZMPOP`.

When any of the sorted sets contains elements, this command behaves exactly like `ZMPOP`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `ZMPOP`.
When all sorted sets are empty, Redis will block the connection until another client adds members to one of the keys or until the `timeout` (a double value specifying the maximum number of seconds to block) elapses.
A `timeout` of zero can be used to block indefinitely.

See `ZMPOP` for more information.
