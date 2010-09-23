@complexity

O(N) (with N being the length of the list)


Set the list element at _index_ (see LINDEX for information about the
_index_ argument) with the new _value_. Out of range indexes will
generate an error. Note that setting the first or last elements of
the list is O(1).

Similarly to other list commands accepting indexes, the index can be negative to access elements starting from the end of the list. So -1 is the last element, -2 is the penultimate, and so forth.

## Return value

[Status code reply][1]



[1]: /p/redis/wiki/ReplyTypes
