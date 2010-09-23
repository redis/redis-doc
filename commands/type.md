@complexity

O(1)


Return the type of the value stored at _key_ in form of a
string. The type can be one of none, string, list, set.
none is returned if the key does not exist.

@return

[Status code reply][1], specifically:

    none if the key does not exis
    string if the key contains a String value
    list if the key contains a List value
    set if the key contains a Set value
    zset if the key contains a Sorted Set value
    hash if the key contains a Hash value

## See also

* Redis Data Types



[1]: /p/redis/wiki/ReplyTypes