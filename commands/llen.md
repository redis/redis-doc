Returns the length of the [Redis list](/docs/data-types/lists) stored at the _key_.
If the _key_ doesn't exist, it is interpreted as an empty list and `0` is returned.
An error is returned when the value stored at the _key_ isn't a list.

@return

@integer-reply: the length of the list at _key_.

@examples

```cli
LPUSH mylist "World"
LPUSH mylist "Hello"
LLEN mylist
```
