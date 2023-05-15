Trim an existing [Redis list](/docs/data-types/lists) so that it will contain only the specified range of elements specified.
Both _start_ and _stop_ are zero-based indexes, where `0` is the first element of the list (the head), `1` is the next element and so on.

For example: `LTRIM foobar 0 2` will modify the list stored at "foobar" so that only the first three elements of the list will remain.

_start_ and _end_ can also be negative numbers indicating offsets from the end of the list, where `-1` is the last element of the list, `-2` is the penultimate element and so on.

Out-of-range indexes will not produce an error: if _start_ is larger than the end of the list, or `start > end`, the result will be an empty list (which causes _key_ to be removed).
If _end_ is larger than the end of the list, Redis will treat it like the last element of the list.

A common use of `LTRIM` is together with `LPUSH` / `RPUSH`.
For example:

```
LPUSH mylist someelement
LTRIM mylist 0 99
```

This pair of commands will push a new element to the list while making sure that the list will not grow larger than 100 elements.
This is very useful when using Redis to store logs for example.
It is important to note that when used in this way `LTRIM` is an O(1) operation because in the average case, just one element is removed from the tail of the list.

@return

@simple-string-reply: `OK`.

@examples

```cli
RPUSH mylist "one"
RPUSH mylist "two"
RPUSH mylist "three"
LTRIM mylist 1 -1
LRANGE mylist 0 -1
```
