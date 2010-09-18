

_Time complexity: O(log(N))_

ZRANK returns the rank of the member in the sorted set, with scores ordered from low to high. ZREVRANK returns the rank with scores ordered from high to low. When the given member does not exist in the sorted set, the special value 'nil' is returned. The returned rank (or index) of the member is 0-based for both commands.

## Return value

[Integer reply][1] or a nil [bulk reply][1], specifically:

	the rank of the element as an integer reply if the element exists.
	A nil bulk reply if there is no such element.



[1]: /p/redis/wiki/ReplyTypes
