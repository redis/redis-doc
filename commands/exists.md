Returns if `key` exists.

@return

@integer-reply, specifically:

* `1` if the key exists.
* `0` if the key does not exist.

@examples

    @cli
    SET key1 "Hello"
    EXISTS key1
    EXISTS key2

