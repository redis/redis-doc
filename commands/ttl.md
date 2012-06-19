Returns the remaining time to live of a key that has a timeout. This
introspection capability allows a Redis client to check how many seconds a given
key will continue to be part of the dataset.

@return

@integer-reply: TTL in seconds or `-1` when `key` does not exist or does not
have a timeout.

@examples

    @cli
    SET mykey "Hello"
    EXPIRE mykey 10
    TTL mykey
