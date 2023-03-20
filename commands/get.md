If `key` doesn't exist the special value `nil` is returned.
An error is returned if the value stored at `key` is not a string, because `GET`
only handles string values.

@return

@bulk-string-reply: the value of `key`, or a @nil-reply when `key` does not exist.

@examples

```cli
GET nonexisting
SET mykey "Hello"
GET mykey
```
