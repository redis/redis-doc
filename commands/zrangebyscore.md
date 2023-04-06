Returns all the members in the sorted set at _key_ with a score between _min_ and _max_ (including members with scores that equal _min_ or _max_).
The members are considered to be ordered from low to high scores.

Members that have the same scores are returned in lexicographical order (this follows from a property of the sorted set implementation in Redis and does not involve further computation).

The optional `LIMIT` argument can be used to only get a range of the matching members (similar to _SELECT LIMIT offset, count_ in SQL).
A negative _count_ returns all members from the _offset_.
Keep in mind that if the _offset_ is large, the sorted set needs to be traversed for _offset_ members before getting to the members to return, which can add up to O(N) time complexity.

The optional `WITHSCORES` argument makes the command return both the member and its score, instead of the member alone.

## Exclusive intervals and infinity

_min_ and _max_ can be `-inf` and `+inf`, so that you are not required to know the highest or lowest score in the sorted set to get all members from or up to a certain score.

By default, the interval specified by _min_ and _max_ is closed (inclusive).
It is possible to specify an open interval (exclusive) by prefixing the score with the left parenthesis (`(`) character.
For example:

```
ZRANGEBYSCORE zset (1 5
```

Will return all elements with `1 < score <= 5` while:

```
ZRANGEBYSCORE zset (5 (10
```

Will return all the members with `5 < score < 10` (5 and 10 excluded).

@return

@array-reply: list of members in the specified score range (optionally with their scores).

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZRANGEBYSCORE myzset -inf +inf
ZRANGEBYSCORE myzset 1 2
ZRANGEBYSCORE myzset (1 2
ZRANGEBYSCORE myzset (1 (2
```

## Pattern: weighted random selection of an element

Normally `ZRANGEBYSCORE` is simply used to get a range of items where the score is the indexed integer key, however, it is possible to do less obvious things with the command.

For example, a common problem when implementing Markov chains and other algorithms is to select an element at random from a set, but different elements may have different weights that change how likely it is they are picked.

This is how we use this command in to implement the algorithm:

Imagine you have elements A, B and C with weights 1, 2 and 3.
You compute the sum of the weights, which is 1+2+3 = 6

At this point you add all the elements into a sorted set using this algorithm:

```
SUM = ELEMENTS.TOTAL_WEIGHT // 6 in this case.
SCORE = 0
FOREACH ELE in ELEMENTS
    SCORE += ELE.weight / SUM
    ZADD KEY SCORE ELE
END
```

This means that you set:

```
A to score 0.16
B to score .5
C to score 1
```

Since this involves approximations, to avoid C is set to, like, 0.998 instead of 1, we just modify the above algorithm to make sure the last score is 1 (left as an exercise for the reader...).

At this point, each time you want to get a weighted random member, just compute a random number between 0 and 1 (which is like calling `rand()` in most languages), so you can just do:

    RANDOM_ELE = ZRANGEBYSCORE key RAND() +inf LIMIT 0 1
