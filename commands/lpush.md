Insert all the specified values at the head of the list stored at the _key_.
If the _key_ doesn't exist, it is created as an empty list before performing the push operations.
When the _key_ holds a value that isn't a list, an error is returned.

It is possible to push multiple elements using a single command call just specifying multiple arguments at the end of the command.
Elements are inserted one after the other to the head of the list, from the leftmost element to the rightmost element.
So, for instance, the command `LPUSH mylist a b c` will result in a list containing "c" as the first element, "b" as the second element and "a" as the third element.

@return

@integer-reply: the length of the list after the push operations.

@examples

```cli
LPUSH mylist "world"
LPUSH mylist "hello"
LRANGE mylist 0 -1
```
