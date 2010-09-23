@complexity

O(log(N)) with N being the number of elements in the sorted
set_

Add the specified _member_ having the specifeid _score_ to the sorted
set stored at _key_. If _member_ is already a member of the sorted se
the score is updated, and the element reinserted in the right position to
ensure sorting. If _key_ does not exist a new sorted set with the specified
_member_ as sole member is crated. If the key exists but does not hold a
sorted set value an error is returned.

The score value can be the string representation of a double precision floating
point number.

For an introduction to sorted sets check the [Introduction to Redis data types][1] page.

@return

@integer-reply, specifically:

	1 if the new element was added
	0 if the element was already a member of the sorted set and the score was updated



[1]: /p/redis/wiki/IntroductionToRedisDataTypes
[2]: /p/redis/wiki/ReplyTypes
