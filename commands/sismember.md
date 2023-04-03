Check and report whether _member_ is a member of the set stored at _key_.

@return

@integer-reply, specifically:

* `1` if the element is a member of the set.
* `0` if the element is not a member of the set, or when _key_ doesn't exist.

@examples

```cli
SADD myset "one"
SISMEMBER myset "one"
SISMEMBER myset "two"
```
