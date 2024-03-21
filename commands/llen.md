Returns the length of the list stored at `key`.
If `key` does not exist, it is interpreted as an empty list and `0` is returned.
An error is returned when the value stored at `key` is not a list.

@examples

```cli
LPUSH mylist "World"
LPUSH mylist "Hello"
LLEN mylist
```
