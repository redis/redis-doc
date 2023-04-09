Sets the element at _index_ to _element_ in the [Redis list](/docs/data-types/lists) that's stored at _key_.
For more information about the _index_ argument, see `LINDEX`.

An error is returned for out-of-range indexes.

@return

@simple-string-reply: `OK`.

@examples

```cli
RPUSH mylist "one"
RPUSH mylist "two"
RPUSH mylist "three"
LSET mylist 0 "four"
LSET mylist -2 "five"
LRANGE mylist 0 -1
```
