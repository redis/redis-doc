Removes and returns the last elements of the list stored at `key`.

By default, the command pops a single element from the end of the list.
When provided with the optional `count` argument, the reply will consist of up
to `count` elements, depending on the list's length.

@return

When called without the `count` argument:

@bulk-string-reply: the value of the last element, or `nil` when `key` does not exist.

When called with the `count` argument:

@array-reply: the values of the last elements, or `nil` when `key` does not exist.

@history

* `>= 6.2`: Added the `count` argument.

@examples

```cli
RPUSH mylist "one"
RPUSH mylist "two"
RPUSH mylist "three"
RPOP mylist
LRANGE mylist 0 -1
```
