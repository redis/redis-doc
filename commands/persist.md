@complexity

O(1)


Remove the existing timeout on `key`.

@return

@integer-reply, specifically:

* `1` if the timeout was removed.
* `0` if `key` does not exist or does not have an associated timeout.

@examples

    @cli
    SET key "Hello"
    EXPIRE key 10
    TTL key
    PERSIST key
    TTL key

