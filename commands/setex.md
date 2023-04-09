Set _key_ to the [Redis string](/docs/data-types/strings) _value_ and its expiry time to _seconds_.

This command is equivalent to:

```
SET key value EX seconds
```


An error is returned when _seconds_ isn't a valid value.

@return

@simple-string-reply: `OK`.

@examples

```cli
SETEX mykey 10 "Hello"
TTL mykey
GET mykey
```
## See also

`TTL`