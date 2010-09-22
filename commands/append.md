

_Time complexity: O(1). The amortized time complexity is O(1) assuming the
appended value is small and the already present value is of any size, since
the dynamic string library used by Redis will double the free space available
on every reallocation._

If the _key_ already exists and is a string, this command appends the
provided value at the end of the string.
If the _key_ does not exist it is created and set as an empty string, so
APPEND will be very similar to SET in this special case.

## Return value

[Integer reply][1], specifically the total length of the string after the append
operation.

## Examples

	redis exists mykey
	(integer) 0
	redis append mykey Hello
	(integer) 6
	redis append mykey World
	(integer) 11
	redis get mykey
	Hello World



[1]: /p/redis/wiki/ReplyTypes
