Returns the string length of the value associated with _field_ in the hash stored at _key_.
If either _key_ or _field_ doesn't exist, 0 is returned.

@return

@integer-reply: the string length of the value associated with _field_, or zero when _field_ is not present in the hash or _key_ doesn't exist at all.

@examples

```cli
HMSET myhash f1 HelloWorld f2 99 f3 -256
HSTRLEN myhash f1
HSTRLEN myhash f2
HSTRLEN myhash f3
```
