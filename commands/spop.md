@complexity

O(1)


Remove a random element from a Set returning it as return value.
If the Set is empty or the key does not exist, a nil object is returned.

The [SRANDMEMBER][1] command does a similar work bu
the returned element is not removed from the Set.

## Return value

[Bulk reply][2]



[1]: /p/redis/wiki/SrandmemberCommand
[2]: /p/redis/wiki/ReplyTypes
