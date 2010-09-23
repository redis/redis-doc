@complexity

O(N) (with N being the number of fields)


Set the respective fields to the respective values. `HMSET` replaces old values with new values.

If _key_ does not exist, a new key holding a hash is created.

@return

[Status code reply][1] Always +OK because `HMSET` can't fail



[1]: /p/redis/wiki/ReplyTypes