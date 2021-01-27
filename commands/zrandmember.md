When called with just the `key` argument, return a random element from the sorted set value stored at `key`.

If the provided `count` argument is positive, return an array of `count` **distinct elements**.
If called with a negative `count`, the behavior changes and the command is allowed to return the **same element multiple times**. In this case, the number of returned elements is the absolute value of the specified `count`.

The optional `WITHSCORES` modifier changes the reply so it includes the respective scores of the randomely selected elements from the sorted set.

@return

@bulk-string-reply: without the additional `count` argument, the command returns a Bulk Reply with the randomly selected element, or `nil` when `key` does not exist.

@array-reply: when the additional `count` argument is passed, the command returns an array of elements, or an empty array when `key` does not exist. If the `WITHSCORES` modifier is used, the reply is a list elements and their scores from the sorted set.

@examples

```cli
ZADD dadi 1 uno 2 due 3 tre 4 quattro 5 cinque 6 sei
ZRANDMEMBER dadi
ZRANDMEMBER dadi
ZRANDMEMBER dadi -5 WITHSCORES
```

## Specification of the behavior when count is passed

When `count` argument is positive, the elements are returned as if every selected element is removed from the sorted set (like the extraction of numbers in the game of Bingo).
However, the actual sorted set isn't altered and elements are **not removed** from it.

So basically:

* No repeated elements are returned.
* If `count` is bigger than the cadinality of the sorted set, the command will only return the whole sorted set without additional elements.
* The order of elements in the reply is not truly random, so it is up to the client to shuffle them if needed.

When the `count` is negative, the behavior changes. The extraction happens as if you return the extracted element to the bag after every extraction, meaning that:

* Repeating elements are possible.
* Exactly `count` elements, or an empty array if the sorted set is empty (non-existing key), are always returned.
* The order of elements in the reply is truly random.
