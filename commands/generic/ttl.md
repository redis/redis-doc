

The TTL command returns the remaining time to live in seconds of a key that has an [EXPIRE][1] set. This introspection capability allows a Redis client to check how many seconds a given key will continue to be part of the dataset. If the Key does not exists or does not have an associated expire, -1 is returned.

## Return value

[Integer reply][2]



[1]: /p/redis/wiki/ExpireCommand
[2]: /p/redis/wiki/ReplyTypes
