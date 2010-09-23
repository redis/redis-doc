@complexity

O(n) (with n being len of list - len of range)


Trim an existing list so that it will contain only the specified
range of elements specified. Start and end are zero-based indexes.
0 is the first element of the list (the list head), 1 the next elemen
and so on.

For example `LTRIM` foobar 0 2 will modify the list stored at foobar
key so that only the first three elements of the list will remain.

_start_ and _end_ can also be negative numbers indicating offsets
from the end of the list. For example -1 is the last element of
the list, -2 the penultimate element and so on.

Indexes out of range will not produce an error: if start is over
the end of the list, or start  end, an empty list is left as value.
If end over the end of the list Redis will threat it just like
the last element of the list.

Hint: the obvious use of `LTRIM` is together with `LPUSH`/`RPUSH`. For example:
            LPUSH mylist someelemen
            LTRIM mylist 0 99
The above two commands will push elements in the list taking care tha
the list will not grow without limits. This is very useful when using
Redis to store logs for example. It is important to note that when used
in this way `LTRIM` is an O(1) operation because in the average case
just one element is removed from the tail of the list.

@return

@status-reply



[1]: /p/redis/wiki/ReplyTypes