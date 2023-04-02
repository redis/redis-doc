`MSET` creates or updates existing values with new values, much like `SET` does.
Also like `SET`, the command ignores the type of existing keys.
See `MSETNX` if you don't want to overwrite existing values.

`MSET` is atomic, so all given keys are set at once.
Clients can't see that some of the keys were updated while others are unchanged.

@return

@simple-string-reply: always `OK` since `MSET` can't fail.

@examples

```cli
MSET key1 "Hello" key2 "World"
GET key1
GET key2
```
