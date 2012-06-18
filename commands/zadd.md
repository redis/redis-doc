Adds all the specified members with the specified scores to the sorted set
stored at `key`. It is possible to specify multiple score/member pairs. If a
specified member is already a member of the sorted set, the score is updated and
the element reinserted at the right position to ensure the correct ordering.
If `key` does not exist, a new sorted set with the specified members as sole
members is created, like if the sorted set was empty. If the key exists but does
not hold a sorted set, an error is returned.

The score values should be the string representation of a numeric value, and
accepts double precision floating point numbers.

For an introduction to sorted sets, see the data types page on [sorted
sets][sorted-sets].

[sorted-sets]: /topics/data-types#sorted-sets

@return

@integer-reply, specifically:

* The number of elements added to the sorted sets, not including elements already existing for which the score was updated.

@history

* `>= 2.4`: Accepts multiple elements. In Redis versions older than 2.4 it was possible to add or update a single member per call.

@examples

    @cli
    ZADD myzset 1 "one"
    ZADD myzset 1 "uno"
    ZADD myzset 2 "two"
    ZADD myzset 3 "two"
    ZRANGE myzset 0 -1 WITHSCORES

