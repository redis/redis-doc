

_Time complexity: O(start+n) (with start being the start index and n the total
length of the requested range). Note that the lookup part of this command is
O(1) so for small strings this is actually an O(1) command._

Return a subset of the string from offset _start_ to offset _end_
(both offsets are inclusive).
Negative offsets can be used in order to provide an offset starting from
the end of the string. So -1 means the last char, -2 the penultimate and
so forth.

The function handles out of range requests without raising an error, bu
just limiting the resulting range to the actual length of the string.

## Return value

[Bulk reply][1]

## Examples

	redis set s This is a string
	OK
	redis substr s 0 3
	This
	redis substr s -3 -1
	ing
	redis substr s 0 -1
	This is a string
	redis substr s 9 100000
	 string



[1]: /p/redis/wiki/ReplyTypes
