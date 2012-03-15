@complexity

O(1)


Set a timeout on `key`. After the timeout has expired, the key will
automatically be deleted. A key with an associated timeout is often said to be
_volatile_ in Redis terminology.

The timeout is cleared only when the key is removed using the `DEL` command or
overwritten using the `SET` or `GETSET` commands. This means that all the
operations that conceptually *alter* the value stored at the key without
replacing it with a new one will leave the timeout untouched. For instance,
incrementing the value of a key with `INCR`, pushing a new value into a list
with `LPUSH`, or altering the field value of a hash with `HSET` are all
operations that will leave the timeout untouched.

The timeout can also be cleared, turning the key back into a persistent key,
using the `PERSIST` command.

If a key is renamed with `RENAME`, the associated time to live is transfered to
the new key name.

If a key is overwritten by `RENAME`, like in the case of an existing key
`Key_A` that is overwritten by a call like `RENAME Key_B Key_A`, it does not
matter if the original `Key_A` had a timeout associated or not, the new key
`Key_A` will inherit all the characteristics of `Key_B`.

Refreshing expires
---

It is possible to call `EXPIRE` using as argument a key that already has an
existing expire set. In this case the time to live of a key is *updated* to the
new value. There are many useful applications for this, an example is
documented in the *Navigation session* pattern section below.

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

Pattern: Navigation session
---

Imagine you have a web service and you are interested in the latest N pages
*recently* visited by your users, such that each adiacent pageview was not
performed more than 60 seconds after the previous. Conceptually you may think
at this set of pageviews as a *Navigation session* if your user, that may
contain interesting informations about what kind of products he or she is
looking for currently, so that you can recommend related products.

You can easily model this pattern in Redis using the following strategy:
every time the user does a pageview you call the following commands:

    MULTI
    RPUSH pagewviews.user:<userid> http://.....
    EXPIRE pagewviews.user:<userid> 60
    EXEC

If the user will be idle more than 60 seconds, the key will be deleted and only
subsequent pageviews that have less than 60 seconds of difference will be
recorded.

This pattern is easily modified to use counters using `INCR` instead of lists
using `RPUSH`.
