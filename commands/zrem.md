@complexity

O(log(N)) with N being the number of elements in the sorted
set_

Remove the specified _member_ from the sorted set value stored at _key_. If
_member_ was not a member of the set no operation is performed. If _key_
does not not hold a set value an error is returned.

@return

@integer-reply, specifically:

    1 if the new element was removed
    0 if the new element was not a member of the se



[1]: /p/redis/wiki/ReplyTypes