Each _key_ argument adds one to the reply if it exists in the currently-selected database.

See the `SELECT` command for more information about logical databases.

Note that if the same key is given multiple times, it will be counted multiple times.
So, if "somekey" exists, then `EXISTS somekey somekey` will return 2.

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
