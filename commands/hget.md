Returns the value associated with _field_ in the hash stored at _key_.

@return

@bulk-string-reply: the value associated with _field_, or @nil-reply when _field_ doesn't exist in the hash or when _key_ doesn't exist.

@examples

```cli
HSET myhash field1 "foo"
HGET myhash field1
HGET myhash field2
```
