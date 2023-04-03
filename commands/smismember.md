Checks and reports whether each _member_ is a member of the set stored at _key_.

For every _member_, `1` is returned if the value is a member of the set.
A `0` is returned for each member that doesn't belong to the set, or if _key_ doesn't exist.

@return

@array-reply: list representing the membership of the given elements, in the same
order as they are requested.

@examples

```cli
SADD myset "one"
SADD myset "one"
SMISMEMBER myset "one" "notamember"
```
