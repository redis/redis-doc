@complexity

O(log(N)) with N being the number of elements in the sorted
set_

If _member_ already exists in the sorted set adds the _increment_ to its score
and updates the position of the element in the sorted set accordingly.
If _member_ does not already exist in the sorted set it is added with
_increment_ as score (that is, like if the previous score was virtually zero).
If _key_ does not exist a new sorted set with the specified
_member_ as sole member is crated. If the key exists but does not hold a
sorted set value an error is returned.

The score value can be the string representation of a double precision floating
point number. It's possible to provide a negative value to perform a decrement.

For an introduction to sorted sets check the [Introduction to Redis data types][1] page.

@return

@bulk-reply

    The new score (a double precision floating point number) represented as string.
    



[1]: /p/redis/wiki/IntroductionToRedisDataTypes
[2]: /p/redis/wiki/ReplyTypes