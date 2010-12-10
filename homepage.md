Redis is an advanced **key-value store**. Keys can contain different
**data structures**, such as [strings](/topics/data-types#strings),
[hashes](/topics/data-types#hashes),
[lists](/topics/data-types#lists), [sets](/topics/data-types#sets) and
[sorted sets](/topics/data-types#sorted-sets). You can run **atomic operations**
on these types, like [appending to a string](/commands/append);
[incrementing the value in a hash](/commands/hincrby); [pushing to a
list](/commands/lpush); [computing set intersection](/commands/sinter),
[union](/commands/sunion) and [difference](/commands/sdiff);
or [getting the member with highest ranking in a sorted
set](/commands/zrangebyscore).
