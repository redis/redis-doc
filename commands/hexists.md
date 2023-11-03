Returns if `field` is an existing field in the hash stored at `key`.

@examples

```cli
HSET myhash field1 "foo"
HEXISTS myhash field1
HEXISTS myhash field2
```
