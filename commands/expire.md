@complexity

O(1)


Set a timeout on `key`. After the timeout has expired, the key will
automatically be deleted. A key with an associated timeout is often said to be
_volatile_ in Redis terminology.

The timeout is cleared only when the key is removed using the [DEL](/commands/del) or overwritten using the [SET](/commands/set) command. This means that all the operations that conceptually *alter* the value stored at key without replacing it with a new one will leave the expire untouched. For instance incrementing the value of a key with [INCR](/commands/incr), pushing a new value into a list with [LPUSH](/commands/lpush), or altering the field value of an Hash with [HSET](/commands/hset), are all operations that will leave the expire untouched.

The timeout can also be cleared, turning the key back into a persistent key,
using the [PERSIST](/commands/persist) command.

If a key is renamed using the [RENAME](/commands/rename) command, the
associated time to live is transfered to the new key name.

If a key is overwritten by [RENAME](commands/rename), like in the
case of an existing key `a` that is overwritten by a call like
`RENAME b a`, it does not matter if the original `a` had a timeout associated
or not, the new key `a` will inherit all the characteristics of `b`.

Expire accuracy
---

In Redis 2.4 the expire might not be pin-point accurate, and it could be
between zero to one seconds out.

Since Redis 2.6 the expire error is from 0 to 1 milliseconds.

Differences in Redis prior 2.1.3
---

In Redis versions prior **2.1.3** altering a key with an expire set using
a command altering its value had the effect of removing the key entirely.
This semantics was needed because of limitations in the replication layer that
are now fixed.

[1]: /topics/expire

@return

@integer-reply, specifically:

* `1` if the timeout was set.
* `0` if `key` does not exist or the timeout could not be set.

@examples

    @cli
    SET mykey "Hello"
    EXPIRE mykey 10
    TTL mykey
    SET mykey "Hello World"
    TTL mykey
