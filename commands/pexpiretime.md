`PEXPIRETIME` has the same semantics as `EXPIRETIME`, but returns the absolute Unix expiration timestamp in milliseconds instead of seconds.

@return

@integer-reply: Expiration Unix timestamp in milliseconds, or a negative value to signal an error (see the description below).

* The command returns `-1` if the _key_ exists but has no associated expiration time.
* The command returns `-2` if the _key_ doesn't exist.

@examples

```cli
SET mykey "Hello"
PEXPIREAT mykey 33177117420000
PEXPIRETIME mykey
```
