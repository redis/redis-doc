Get the value of `key` and delete the key.
This command is identical to `GET`, except for the fact that it also deletes the key.

@return

@bulk-string-reply: the value of `key`, or `nil` when `key` does not exist.

@examples

```cli
SET mykey "Hello"
GETDEL mykey
GET mykey
```
