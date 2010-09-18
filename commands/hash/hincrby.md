

_Time complexity: O(1)_

Increment the number stored at _field_ in the hash at _key_ by _value_. If _key_ does not exist, a new key holding a hash is created. If _field_ does not exist or holds a string, the value is set to 0 before applying the operation.

The range of values supported by HINCRBY is limited to 64 bit signed integers.

## Examples

Since the _value_ argument is signed you can use this command to perform both
increments and decrements:

	HINCRBY key field 1 (increment by one)
	HINCRBY key field -1 (decrement by one, just like the DECR command)
	HINCRBY key field -10 (decrement by 10)

## Return value

[Integer reply][1] The new value at _field_ after the increment operation.




[1]: /p/redis/wiki/ReplyTypes
