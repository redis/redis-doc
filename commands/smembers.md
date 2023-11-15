Returns all the members of the set value stored at `key`.

This has the same effect as running `SINTER` with one argument `key`.

@examples

```cli
SADD myset "Hello"
SADD myset "World"
SMEMBERS myset
```
