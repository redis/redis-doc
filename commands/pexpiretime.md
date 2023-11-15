`PEXPIRETIME` has the same semantic as `EXPIRETIME`, but returns the absolute Unix expiration timestamp in milliseconds instead of seconds.

@examples

```cli
SET mykey "Hello"
PEXPIREAT mykey 33177117420000
PEXPIRETIME mykey
```
