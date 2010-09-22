

_Time complexity: O(1)_

The command is exactly equivalent to the following group of commands:
	SET _key_ _value_
	EXPIRE _key_ _time_The operation is atomic. An atomic [SET][1]+[EXPIRE][2]
operation was already provided
using [MULTI/EXEC][3], but SETEX is a faster alternative provided
because this operation is very common when Redis is used as a Cache.

## Return value

[Status code reply][4]



[1]: /p/redis/wiki/SetCommand
[2]: /p/redis/wiki/ExpireCommand
[3]: /p/redis/wiki/MultiExecCommand
[4]: /p/redis/wiki/ReplyTypes
