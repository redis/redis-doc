When called with just the _key_ argument, return a random member from the [Redis sorted set](/docs/data-types/sorted-sets) value stored at _key_.

If the provided _count_ argument is positive, return an array of **distinct members**.
The array's length is either _count_ or the sorted set's cardinality (`ZCARD`), whichever is lower.

If called with a negative _count_, the behavior changes and the command is allowed to return the **same member multiple times**.
In this case, the number of returned members is the absolute value of the specified _count_.

The optional `WITHSCORES` modifier changes the reply so it includes the respective scores of the randomly selected member from the sorted set.

@return

@bulk-string-reply: without the additional _count_ argument, the command returns the randomly selected member, or @nil-reply when _key_ doesn't exist.

@array-reply: when the additional _count_ argument is passed, the command returns an array of members, or an empty array when _key_ doesn't exist.
If the `WITHSCORES` modifier is used, the reply is a list of members and their scores from the sorted set.

@examples

```cli
ZADD dadi 1 uno 2 due 3 tre 4 quattro 5 cinque 6 sei
ZRANDMEMBER dadi
ZRANDMEMBER dadi
ZRANDMEMBER dadi -5 WITHSCORES
```

## Specification of the behavior when count is passed

When the _count_ argument is a positive value this command behaves as follows:

* No repeated elements are returned.
* If the _count_ is bigger than the cardinality of the sorted set, the command will only return the whole sorted set without additional elements.
* The order of elements in the reply is not truly random, so it is up to the client to shuffle them if needed.

When the _count_ is a negative value, the behavior changes as follows:

* Repeating elements are possible.
* Exactly _count_ elements, or an empty array if the sorted set is empty (non-existing key), are always returned.
* The order of elements in the reply is truly random.
