@complexity

O(1)


Set a timeout on `key`. After the timeout has expired, the key will
automatically be deleted. A key with an associated timeout is said to be
_volatile_ in Redis terminology.

If `key` is updated before the timeout has expired, then the timeout is removed
as if the `PERSIST` command was invoked on `key`.

For Redis versions **< 2.1.3**, existing timeouts cannot be overwritten. So, if
`key` already has an associated timeout, it will do nothing and return `0`.
Since Redis **2.1.3**, you can update the timeout of a key. It is also possible
to remove the timeout using the `PERSIST` command. See the page on [key expiry][1]
for more information.

Note that expire might not be pin-point accurate it; could be anywhere
between zero to one seconds out.

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
