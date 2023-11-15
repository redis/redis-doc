Returns whether each `member` is a member of the set stored at `key`.

For every `member`, `1` is returned if the value is a member of the set, or `0` if the element is not a member of the set or if `key` does not exist.

@examples

```cli
SADD myset "one"
SADD myset "one"
SMISMEMBER myset "one" "notamember"
```
