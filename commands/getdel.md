This command is similar to `GET`, except for the fact that it also deletes the _key_ on success (if, and only if, the key's value type is a [Redis string](/docs/data-types/strings)).

@return

@bulk-string-reply: the value of _key_, @nil-reply when _key_ doesn't exist, or an error if the key's value type isn't a string.

@examples

```cli
SET mykey "Hello"
GETDEL mykey
GET mykey
```
