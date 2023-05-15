This command is very similar to `DEL`: it removes the specified keys.

Just like `DEL` a key is ignored if it doesn't exist.

However, `UNLINK` performs the actual memory reclaiming in a different thread, so it isn't blocking, while `DEL` is.
This is where the command name comes from: the command just **unlinks** the keys from the keyspace.
The actual removal will happen asynchronously later.

@return

@integer-reply: The number of keys that were unlinked.

@examples

```cli
SET key1 "Hello"
SET key2 "World"
UNLINK key1 key2 key3
```
