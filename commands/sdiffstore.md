This command is identical to `SDIFF`, but instead of returning the resulting set, it is stored in _destination_.

If `destination` already exists, it is overwritten.

@return

@integer-reply: the number of elements in the resulting set.

@examples

```cli
SADD key1 "a"
SADD key1 "b"
SADD key1 "c"
SADD key2 "c"
SADD key2 "d"
SADD key2 "e"
SDIFFSTORE key key1 key2
SMEMBERS key
```
