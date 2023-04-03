When called with just the _key_ argument, return a random member of the set that's stored at _key_.

If the provided _count_ argument is positive, return an array of **distinct members**.
The array's length is either _count_ or the set's cardinality (`SCARD`), whichever is lower.

If called with a negative _count_, the behavior changes and the command is allowed to return the **same members multiple times**.
In this case, the number of returned members is the absolute value of the specified _count_.

@return

@bulk-string-reply: without the additional _count_ argument, the command returns the randomly selected member, or @nil-reply when _key_ doesn't exist.

@array-reply: when the optional _count_ argument is passed, the command returns an array of members, or an empty array when _key_ doesn't exist.

@examples

```cli
SADD myset one two three
SRANDMEMBER myset
SRANDMEMBER myset 2
SRANDMEMBER myset -5
```

## Specification of the behavior when count is used

When the _count_ argument is a positive value this command behaves as follows:

* No repeated elements are returned.
* If _count_ is bigger than the set's cardinality, the command will only return the whole set without additional elements.
* The order of elements in the reply is not truly random, so it is up to the client to shuffle them if needed.

When the _count_ is a negative value, the behavior changes as follows:

* Repeating elements are possible.
* Exactly _count_ elements, or an empty array if the set is empty (non-existing key), are always returned.
* The order of elements in the reply is truly random.

## Distribution of returned elements

Note: this section is relevant only for Redis 5 or below, as Redis 6 implements a fairer algorithm. 

The distribution of the returned elements is far from perfect when the number of elements in the set is small, this is because we used an approximated random element function that doesn't guarantees good distribution.

The algorithm used, which is implemented inside dict.c, samples the hash table buckets to find a non-empty one.
Once a nonempty bucket is found, since we use chaining in our hash table implementation, the number of elements inside the bucket is checked and a random element is selected.

This means that if you have two non-empty buckets in the entire hash table, and one has three elements while one has just one, the element that is alone in its bucket will be returned with a much higher probability.
