Removes and returns the last elements of the list stored at `key`.

By default, the command pops a single element from the end of the list.
When provided with the optional `count` argument, the reply will consist of up
to `count` elements, depending on the list's length.

@return

When called without the `count` argument:

@bulk-string-reply: the value of the last element, or `nil` when `key` does not exist.

When called with the `count` argument:

@array-reply: list of popped elements, or `nil` when `key` does not exist.

@examples

```cli
RPUSH mylist "one" "two" "three" "four" "five"
RPOP mylist
RPOP mylist 2
LRANGE mylist 0 -1
```
