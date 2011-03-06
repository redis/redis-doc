@complexity

O(1)


Removes `field` from the hash stored at `key`.

@return

@integer-reply: specifically,

* `1` if `field` was present in the hash and is now removed.
* `0` if `field` does not exist in the hash, or `key` does not exist.

@examples

    @cli
    HSET myhash field1 "foo"
    HDEL myhash field1
    HDEL myhash field2

