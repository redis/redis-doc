Keys that don't exist are silently ignored and aren't included in the reply.

@return

@integer-reply: The number of keys that were removed.

@examples

```cli
SET key1 "Hello"
SET key2 "World"
DEL key1 key2 key3
```
