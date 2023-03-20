Each `key` argument adds one to the reply if it exists in the database.

Note that if the same existing key is mentioned in the arguments multiple times, it will be counted multiple times.
So, if `somekey` exists, then `EXISTS somekey somekey` will return 2.

@return

@integer-reply: the number of keys that exist.

@examples

```cli
SET key1 "Hello"
EXISTS key1
EXISTS nosuchkey
SET key2 "World"
EXISTS key1 key2 nosuchkey
```
