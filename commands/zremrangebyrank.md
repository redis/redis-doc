@complexity

O(log(N))+O(M) with N being the number of elements in the
sorted set and M the number of elements removed by the operation_

Remove all elements in the sorted set at _key_ with rank between _start_ and _end_. Start and end are 0-based with rank 0 being the element with the lowest score. Both start and end can be negative numbers, where they indicate offsets starting at the element with the highest rank. For example: -1 is the element with the highest score, -2 the element with the second highest score and so forth.

## Return value

[Integer reply][1], specifically the number of elements removed.



[1]: /p/redis/wiki/ReplyTypes
