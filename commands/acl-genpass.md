[Access Control List (ACL)](/docs/management/security/acl) users need a solid password to authenticate with the server without security risks.
Such password isn't meant to be remembered by humans, only by computers, so it can be very long and strong (unguessable by an external attacker).
The `ACL GENPASS` command generates a password starting from `/dev/urandom` if available, otherwise (in systems without `/dev/urandom`) it uses a weaker system that is likely still better than picking a weak password by hand.

By default, when `/dev/urandom` is available, the password is strong and can be used for other uses in the context of a Redis application, such as creating unique session identifiers and other types of unguessable, non-colliding IDs.
The password generation is also very cheap because we don't ask `/dev/urandom` for bits at every execution.
At startup Redis creates a seed using `/dev/urandom`, then it will use `SHA256` in counter mode, with `HMAC-SHA256(seed,counter)` as primitive, to create more random bytes as needed.
This means that the application developer can feel free to abuse `ACL GENPASS` to create as many secure pseudorandom strings as needed.

The command output is a hexadecimal representation of a binary string.
By default, it emits 256 bits (or 64 hexadecimal characters).
The user can provide, as the _bits_ argument, a number between 1 and 1024, as the number of bits to emit.
Note that the number of bits is always rounded up to the next multiple of 4.
So, for instance, asking for a password that's 1 bit long, will result in 4 bits being emitted, in the form of a single hexadecimal character.

@return

@bulk-string-reply: by default 64 bytes string representing 256 bits of pseudorandom data.
Otherwise, if an argument is given, the output string length is the number of specified bits (rounded to the next multiple of 4) divided by 4.

@examples

```
> ACL GENPASS
"dd721260bfe1b3d9601e7fbab36de6d04e2e67b0ef1c53de59d45950db0dd3cc"

> ACL GENPASS 32
"355ef3dd"

> ACL GENPASS 5
"90"
```
