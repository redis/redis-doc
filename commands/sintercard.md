This command is similar to `SINTER`, but instead of returning the resulting set's members, it returns the cardinality (number of members) of the operation.

Keys that don't exist are considered to be empty sets.
Therefore, if even one of the keys doesn't exist, the resulting set is also empty, since the intersection with an empty set always results in an empty set.

By default, the command calculates the cardinality of the intersection of all given sets.
When provided with the optional `LIMIT` argument (which defaults to 0, which means unlimited), if the intersection cardinality reaches the _limit_ partway through the computation, the algorithm will exit and yield _limit_ as the cardinality.
This implementation ensures a significant speedup for queries where the _limit_ is lower than the actual intersection cardinality.

@return

@integer-reply: the number of elements in the resulting intersection.

@examples

```cli
SADD key1 "a"
SADD key1 "b"
SADD key1 "c"
SADD key1 "d"
SADD key2 "c"
SADD key2 "d"
SADD key2 "e"
SINTER key1 key2
SINTERCARD 2 key1 key2
SINTERCARD 2 key1 key2 LIMIT 1
```
