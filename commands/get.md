If _key_ doesn't exist, the special value `nil` is returned.
An error is returned if the value stored at _key_ isn't a [Redis string](/docs/data-types/strings), because `GET` only handles string values.

@return

@bulk-string-reply: the value of _key_, or a @nil-reply when _key_ doesn't exist.

@examples

```cli
GET nonexisting
SET mykey "Hello"
GET mykey
```
