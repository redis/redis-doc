@complexity

O(N) with N being the total number of elements of all the
sets_

Return the members of a set resulting from the difference between the firs
set provided and all the successive sets. Example:
	key1 = x,a,b,c
	key2 = c
	key3 = a,d
	SDIFF key1,key2,key3 = x,b
Non existing keys are considered like empty sets.

## Return value

[Multi bulk reply][1], specifically the list of common elements.



[1]: /p/redis/wiki/ReplyTypes
