@complexity

O(1)


`BRPOP` is a blocking list pop primitive.  It is the blocking version of `RPOP`
because it blocks the connection when there are no elements to pop from any of
the given lists. An element is popped from the tail of the first list that is
non-empty, with the given keys being checked in the order that they are given.

See `BLPOP` for the exact semantics. `BRPOP` is identical to `BLPOP`, apart
from popping from the tail of a list instead of the head of a list.

@return

@multi-bulk-reply: specifically:

* A `nil` multi-bulk when no element could be popped and the timeout expired.
* A two-element multi-bulk with the first element being the name of the key where an element
  was popped and the second element being the value of the popped element.

