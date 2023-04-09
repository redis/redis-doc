Returns the string length of the value associated with the _field_ in the [Redis hash](/docs/data-types/hashes) stored at the _key_.
If either _key_ or _field_ doesn't exist, 0 is returned.

@return

@integer-reply: the string length of the value associated with the _field_, or zero when the _field_ isn't present in the hash or the _key_ doesn't exist at all.

@examples

```cli
HMSET myhash f1 HelloWorld f2 99 f3 -256
HSTRLEN myhash f1
HSTRLEN myhash f2
HSTRLEN myhash f3
```
