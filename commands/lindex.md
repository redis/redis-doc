@complexity

O(n) (with n being the length of the list)


Return the specified element of the list stored at the specified
key. 0 is the first element, 1 the second and so on. Negative indexes
are supported, for example -1 is the last element, -2 the penultimate
and so on.

If the value stored at key is not of list type an error is returned.
If the index is out of range a 'nil' reply is returned.

Note that even if the average time complexity is O(n) asking for
the first or the last element of the list is O(1).

@return

@bulk-reply, specifically the requested element.



[1]: /p/redis/wiki/ReplyTypes