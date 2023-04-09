Adds all the specified values to the tail of the [Redis list](/docs/data-types/lists) stored at _key_.
If the _key_ doesn't exist, it is created as an empty list before performing the push
operation.
When the _key_ holds a value that isn't a list, an error is returned.

It is possible to push multiple elements using a single command call just specifying multiple arguments at the end of the command.
Elements are inserted one after the other to the tail of the list, from the leftmost element to the rightmost element.
So, for instance, the command `RPUSH mylist a b c` will result in a list containing "a" as the first element, "b" as the second element and "c" as the third element.

@return

@integer-reply: the length of the list after the push operation.

@examples

```cli
RPUSH mylist "hello"
RPUSH mylist "world"
LRANGE mylist 0 -1
```
