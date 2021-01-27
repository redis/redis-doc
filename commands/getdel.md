Get the value of `key` and delete the key. Return values are similar as `GET`.

@return

@bulk-string-reply: the value of `key`, or `nil` when `key` does not exist.

@examples

```cli
SET mykey "Hello"
GETDEL mykey
GET mykey
```