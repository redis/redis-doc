When called with just the `key` argument, return a random element from the set value stored at `key`.

If the provided `count` argument is positive, return an array of `count` **distinct elements**.
If called with a negative `count`, the behavior changes and the command is allowed to return the **same element multiple times**. In this case, the number of returned elements is the absolute value of the specified `count`.

Conceptually, this command is similar to `SPOP`. However, while `SPOP` also removes the randomly selected element from the set, `SRANDMEMBER` only returns a random element without altering the original set in any way.

@return

@bulk-string-reply: without the additional `count` argument, the command returns a Bulk Reply with the randomly selected element, or `nil` when `key` does not exist.

@array-reply: when the additional `count` argument is passed, the command returns an array of elements, or an empty array when `key` does not exist.

@examples

```cli
SADD myset one two three
SRANDMEMBER myset
SRANDMEMBER myset 2
SRANDMEMBER myset -5
```

@history

* `>= 2.6.0`: Added the optional `count` argument.

## Specification of the behavior when count is passed

When `count` argument is positive, the elements are returned as if every selected element is removed from the set (like the extraction of numbers in the game of Bingo).
However, the actual set isn't altered and elements are **not removed** from it.

So basically:

* No repeated elements are returned.
* If `count` is bigger than the set's cardinality, the command will only return the whole set without additional elements.
* The order of elements in the reply is not truly random, so it is up to the client to shuffle them if needed.

When the `count` is negative, the behavior changes. The extraction happens as if you return the extracted element to the bag after every extraction, meaning that:

* Repeating elements are possible.
* Exactly `count` elements, or an empty array if the set is empty (non-existing key), are always returned.
* The order of elements in the reply is truly random.

## Distribution of returned elements

Note: this section is relevant only for Redis 5 or below, as Redis 6 implements a fairer algorithm. 

The distribution of the returned elements is far from perfect when the number of elements in the set is small, this is due to the fact that we used an approximated random element function that does not really guarantees good distribution.

The algorithm used, that is implemented inside dict.c, samples the hash table buckets to find a non-empty one. Once a non empty bucket is found, since we use chaining in our hash table implementation, the number of elements inside the bucket is checked and a random element is selected.

This means that if you have two non-empty buckets in the entire hash table, and one has three elements while one has just one, the element that is alone in its bucket will be returned with much higher probability.
