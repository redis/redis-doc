@complexity

O(1)


Returns if `field` is an existing field in the hash stored at `key`.

@return

@integer-reply, specifically:

* `1` if the hash contains `field`.
* `0` if the hash does not contain `field`, or `key` does not exist.

@examples

    @cli
    HSET hash field1 "foo"
    HEXISTS hash field1
    HEXISTS hash field2

