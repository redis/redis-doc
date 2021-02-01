Get the value of `key` and delete the key.
This command is similarly to `GET`, except for the fact that it also deletes the key on success (only if the key is string type).

@return

@bulk-string-reply: the value of `key`, `nil` when `key` does not exist, or error if the key is not a string type.

@examples

```cli
SET mykey "Hello"
GETDEL mykey
GET mykey
```
