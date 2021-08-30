`BLMPOP` is the blocking variant of `LMPOP`.

When lists contains elements, this command behaves exactly like `LMPOP`.
When used inside a `MULTI`/`EXEC` block, this command behaves exactly like `LMPOP`.
When lists are empty, Redis will block the connection until another client
pushes to it or until `timeout` (a double value specifying the maximum number
of seconds to block) is reached.
A `timeout` of zero can be used to block indefinitely.

See `LMPOP` for more information.

@return

@array-reply: specifically:

* A `nil` multi-bulk when no element could be popped, and timeout is reached.
* A two-element multi-bulk with the first element being the name of the key where
  elements was popped, and the second element is a multi-bulk with an array of elements.

@examples

```cli
DEL mylist mylist2
LPUSH mylist "one" "two" "three" "four" "five"
BLMPOP 1 1 mylist LEFT COUNT 2
LRANGE mylist 0 -1
LPUSH mylist2 "a" "b" "c" "d" "e"
BLMPOP 1 2 mylist mylist2 LEFT COUNT 3
LRANGE mylist 0 -1
BLMPOP 1 2 mylist mylist2 RIGHT COUNT 10
LRANGE mylist2 0 -1
EXISTS mylist mylist2
```
