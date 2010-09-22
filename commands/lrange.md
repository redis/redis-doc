

_Time complexity: O(start+n) (with n being the length of the range and star
being the start offset)_

Return the specified elements of the list stored at the specified key. Star
and end are zero-based indexes. 0 is the first element of the list (the lis
head), 1 the next element and so on.

For example LRANGE foobar 0 2 will return the first three elements of the list.


_start_ and _end_ can also be negative numbers indicating offsets from the
end of the list. For example -1 is the last element of the list, -2 the penultimate
element and so on.

## Consistency with range functions in various programming language

Note that if you have a list of numbers from 0 to 100, LRANGE 0 10 will return
11 elements, that is, rightmost item is included. This **may or may not** be
consistent with behavior of range-related functions in your programming language
of choice (think Ruby's Range.new, Array#slice or Python's range() function).


LRANGE behavior is consistent with one of Tcl.

## Out-of-range indexes

Indexes out of range will not produce an error: if start is over the end of
the list, or start end, an empty list is returned. If end is over the end of
the list Redis will threat it just like the last element of the list.

## Return value

[Multi bulk reply][1], specifically a list of elements in the specified range.




[1]: /p/redis/wiki/ReplyTypes
