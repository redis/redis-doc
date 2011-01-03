@complexity

O(1)


Set a timeout on `key`. After the timeout has expired, the key will
automatically be deleted. A key with an associated timeout is said to be
_volatile_ in Redis terminology.

For Redis versions **< 2.1.3**, existing timeouts cannot be overwritten. So, if
`key` already has an associated timeout, it will do nothing and return `0`.
Since Redis **2.1.3**, you can update the timeout of a key. It is also possible
to remove the timeout using the `PERSIST` command. See the page on [key expiry][1]
for more information.

[1]: /topics/expire

@return

@integer-reply, specifically:

* `1` if the timeout was set.
* `0` if `key` does not exist or the timeout could not be set.

@examples

    @cli
    SET key "Hello"
    EXPIRE key 10
    TTL key

