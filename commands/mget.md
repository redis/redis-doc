@complexity

O(1) for every key


Get the values of all the specified keys. If one or more keys dont exis
or is not of type String, a 'nil' value is returned instead of the value
of the specified key, but the operation never fails.

## Return value

[Multi bulk reply][1]

## Example

	$ ./redis-cli set foo 1000
	+OK
	$ ./redis-cli set bar 2000
	+OK
	$ ./redis-cli mget foo bar
	1. 1000
	2. 2000
	$ ./redis-cli mget foo bar nokey
	1. 1000
	2. 2000
	3. (nil)
	$



[1]: /p/redis/wiki/ReplyTypes
