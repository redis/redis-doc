`BZMPOP` is the blocking variant of `ZMPOP`.

When any of the sorted sets contains elements, this command behaves exactly like `ZMPOP`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `ZMPOP`.
When all sorted sets are empty, Redis will block the connection until another client adds members to one of the keys or until the `timeout` (a double value specifying the maximum number of seconds to block) elapses.
A `timeout` of zero can be used to block indefinitely.

See `ZMPOP` for more information.

@return

@array-reply: specifically:

* A `nil` when no element could be popped.
* A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.

@examples

```cli
DEL myzset myzset2
ZADD myzset 1 "one" 2 "two" 3 "three"
BZMPOP 1 1 myzset MIN COUNT 2
ZRANGE myzset 0 -1 WITHSCORES
ZADD myzset2 4 "four" 5 "five" 6 "six"
ZMPOP 2 myzset myzset2 MIN COUNT 1
ZRANGE myzset 0 -1 WITHSCORES
ZMPOP 2 myzset myzset2 MAX count 10
ZRANGE myzset2 0 -1 WITHSCORES
EXISTS myzset myzset2
```
