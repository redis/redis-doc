

_Time complexity: O(1)_

GETSET is an atomic _set this value and return the old value_ command.
Set _key_ to the string _value_ and return the old value stored at _key_.
The string can't be longer than 1073741824 bytes (1 GB).

## Return value

[Bulk reply][1]

## Design patterns

GETSET can be used together with INCR for counting with atomic reset when
a given condition arises. For example a process may call INCR against the
key _mycounter_ every time some event occurred, but from time to
time we need to get the value of the counter and reset it to zero atomically
using GETSET mycounter 0.



[1]: /p/redis/wiki/ReplyTypes
