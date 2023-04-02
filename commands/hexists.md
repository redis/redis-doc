Returns whether _field_ exists in the hash stored at _key_.

@return

@integer-reply, specifically:

* `1` if the hash contains the _field_.
* `0` if the hash doesn't contain the _field_, or _key_ doesn't exist.

@examples

```cli
HSET myhash field1 "foo"
HEXISTS myhash field1
HEXISTS myhash field2
```
