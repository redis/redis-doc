---
title: "Redis sorted sets"
linkTitle: "Sorted sets"
weight: 50
description: >
    Introduction to Redis sorted sets
---

A Redis sorted set is a collection of unique strings (members) ordered by an associated score.
When more than one string has the same score, the strings are ordered lexicographically.
Some use cases for sorted sets include:

* Leaderboards. For example, you can use sorted sets to easily maintain  ordered lists of the highest scores in a massive online game.
* Rate limiters. In particular, you can use a sorted set to build a sliding-window rate limiter to prevent excessive API requests.

You can think of sorted sets as a mix between a Set and
a Hash. Like sets, sorted sets are composed of unique, non-repeating
string elements, so in some sense a sorted set is a set as well.

However while elements inside sets are not ordered, every element in
a sorted set is associated with a floating point value, called *the score*
(this is why the type is also similar to a hash, since every element
is mapped to a value).

Moreover, elements in a sorted set are *taken in order* (so they are not
ordered on request, order is a peculiarity of the data structure used to
represent sorted sets). They are ordered according to the following rule:

* If B and A are two elements with a different score, then A > B if A.score is > B.score.
* If B and A have exactly the same score, then A > B if the A string is lexicographically greater than the B string. B and A strings can't be equal since sorted sets only have unique elements.

Let's start with a simple example, adding a few selected hackers names as
sorted set elements, with their year of birth as "score".

    > zadd hackers 1940 "Alan Kay"
    (integer) 1
    > zadd hackers 1957 "Sophie Wilson"
    (integer) 1
    > zadd hackers 1953 "Richard Stallman"
    (integer) 1
    > zadd hackers 1949 "Anita Borg"
    (integer) 1
    > zadd hackers 1965 "Yukihiro Matsumoto"
    (integer) 1
    > zadd hackers 1914 "Hedy Lamarr"
    (integer) 1
    > zadd hackers 1916 "Claude Shannon"
    (integer) 1
    > zadd hackers 1969 "Linus Torvalds"
    (integer) 1
    > zadd hackers 1912 "Alan Turing"
    (integer) 1


As you can see `ZADD` is similar to `SADD`, but takes one additional argument
(placed before the element to be added) which is the score.
`ZADD` is also variadic, so you are free to specify multiple score-value
pairs, even if this is not used in the example above.

With sorted sets it is trivial to return a list of hackers sorted by their
birth year because actually *they are already sorted*.

Implementation note: Sorted sets are implemented via a
dual-ported data structure containing both a skip list and a hash table, so
every time we add an element Redis performs an O(log(N)) operation. That's
good, but when we ask for sorted elements Redis does not have to do any work at
all, it's already all sorted:

    > zrange hackers 0 -1
    1) "Alan Turing"
    2) "Hedy Lamarr"
    3) "Claude Shannon"
    4) "Alan Kay"
    5) "Anita Borg"
    6) "Richard Stallman"
    7) "Sophie Wilson"
    8) "Yukihiro Matsumoto"
    9) "Linus Torvalds"

Note: 0 and -1 means from element index 0 to the last element (-1 works
here just as it does in the case of the `LRANGE` command).

What if I want to order them the opposite way, youngest to oldest?
Use `ZREVRANGE` instead of `ZRANGE`:

    > zrevrange hackers 0 -1
    1) "Linus Torvalds"
    2) "Yukihiro Matsumoto"
    3) "Sophie Wilson"
    4) "Richard Stallman"
    5) "Anita Borg"
    6) "Alan Kay"
    7) "Claude Shannon"
    8) "Hedy Lamarr"
    9) "Alan Turing"

It is possible to return scores as well, using the `WITHSCORES` argument:

    > zrange hackers 0 -1 withscores
    1) "Alan Turing"
    2) "1912"
    3) "Hedy Lamarr"
    4) "1914"
    5) "Claude Shannon"
    6) "1916"
    7) "Alan Kay"
    8) "1940"
    9) "Anita Borg"
    10) "1949"
    11) "Richard Stallman"
    12) "1953"
    13) "Sophie Wilson"
    14) "1957"
    15) "Yukihiro Matsumoto"
    16) "1965"
    17) "Linus Torvalds"
    18) "1969"

### Operating on ranges

Sorted sets are more powerful than this. They can operate on ranges.
Let's get all the individuals that were born up to 1950 inclusive. We
use the `ZRANGEBYSCORE` command to do it:

    > zrangebyscore hackers -inf 1950
    1) "Alan Turing"
    2) "Hedy Lamarr"
    3) "Claude Shannon"
    4) "Alan Kay"
    5) "Anita Borg"

We asked Redis to return all the elements with a score between negative
infinity and 1950 (both extremes are included).

It's also possible to remove ranges of elements. Let's remove all
the hackers born between 1940 and 1960 from the sorted set:

    > zremrangebyscore hackers 1940 1960
    (integer) 4

`ZREMRANGEBYSCORE` is perhaps not the best command name,
but it can be very useful, and returns the number of removed elements.

Another extremely useful operation defined for sorted set elements
is the get-rank operation. It is possible to ask what is the
position of an element in the set of the ordered elements.

    > zrank hackers "Anita Borg"
    (integer) 4

The `ZREVRANK` command is also available in order to get the rank, considering
the elements sorted a descending way.

### Lexicographical scores

In version Redis 2.8, a new feature was introduced that allows
getting ranges lexicographically, assuming elements in a sorted set are all
inserted with the same identical score (elements are compared with the C
`memcmp` function, so it is guaranteed that there is no collation, and every
Redis instance will reply with the same output).

The main commands to operate with lexicographical ranges are `ZRANGEBYLEX`,
`ZREVRANGEBYLEX`, `ZREMRANGEBYLEX` and `ZLEXCOUNT`.

For example, let's add again our list of famous hackers, but this time
use a score of zero for all the elements:

    > zadd hackers 0 "Alan Kay" 0 "Sophie Wilson" 0 "Richard Stallman" 0
      "Anita Borg" 0 "Yukihiro Matsumoto" 0 "Hedy Lamarr" 0 "Claude Shannon"
      0 "Linus Torvalds" 0 "Alan Turing"

Because of the sorted sets ordering rules, they are already sorted
lexicographically:

    > zrange hackers 0 -1
    1) "Alan Kay"
    2) "Alan Turing"
    3) "Anita Borg"
    4) "Claude Shannon"
    5) "Hedy Lamarr"
    6) "Linus Torvalds"
    7) "Richard Stallman"
    8) "Sophie Wilson"
    9) "Yukihiro Matsumoto"

Using `ZRANGEBYLEX` we can ask for lexicographical ranges:

    > zrangebylex hackers [B [P
    1) "Claude Shannon"
    2) "Hedy Lamarr"
    3) "Linus Torvalds"

Ranges can be inclusive or exclusive (depending on the first character),
also string infinite and minus infinite are specified respectively with
the `+` and `-` strings. See the documentation for more information.

This feature is important because it allows us to use sorted sets as a generic
index. For example, if you want to index elements by a 128-bit unsigned
integer argument, all you need to do is to add elements into a sorted
set with the same score (for example 0) but with a 16 byte prefix
consisting of **the 128 bit number in big endian**. Since numbers in big
endian, when ordered lexicographically (in raw bytes order) are actually
ordered numerically as well, you can ask for ranges in the 128 bit space,
and get the element's value discarding the prefix.

If you want to see the feature in the context of a more serious demo,
check the [Redis autocomplete demo](http://autocomplete.redis.io).

Updating the score: leaderboards
---

Just a final note about sorted sets before switching to the next topic.
Sorted sets' scores can be updated at any time. Just calling `ZADD` against
an element already included in the sorted set will update its score
(and position) with O(log(N)) time complexity.  As such, sorted sets are suitable
when there are tons of updates.

Because of this characteristic a common use case is leaderboards.
The typical application is a Facebook game where you combine the ability to
take users sorted by their high score, plus the get-rank operation, in order
to show the top-N users, and the user rank in the leader board (e.g., "you are
the #4932 best score here").

## Examples

* Update a real-time leaderboard as players' scores change:
```
> ZADD leaderboard:455 100 user:1
(integer) 1
> ZADD leaderboard:455 75 user:2
(integer) 1
> ZADD leaderboard:455 101 user:3
(integer) 1
> ZADD leaderboard:455 15 user:4
(integer) 1
> ZADD leaderboard:455 275 user:2
(integer) 0
```

Notice that `user:2`'s score is updated in the final `ZADD` call.

* Get the top 3 players' scores:
```
> ZRANGE leaderboard:455 0 2 REV WITHSCORES
1) "user:2"
2) "275"
3) "user:3"
4) "101"
5) "user:1"
6) "100"
```

* What's the rank of user 2?
```
> ZREVRANK leaderboard:455 user:2
(integer) 0
```

## Basic commands

* `ZADD` adds a new member and associated score to a sorted set. If the member already exists, the score is updated.
* `ZRANGE` returns members of a sorted set, sorted within a given range.
* `ZRANK` returns the rank of the provided member, assuming the sorted is in ascending order.
* `ZREVRANK` returns the rank of the provided member, assuming the sorted set is in descending order.
 
See the [complete list of sorted set commands](https://redis.io/commands/?group=sorted-set).

## Performance

Most sorted set operations are O(log(n)), where _n_ is the number of members.

Exercise some caution when running the `ZRANGE` command with large returns values (e.g., in the tens of thousands or more).
This command's time complexity is O(log(n) + m), where _m_ is the number of results returned. 

## Alternatives

Redis sorted sets are sometimes used for indexing other Redis data structures.
If you need to index and query your data, consider the [JSON](/docs/stack/json) data type and the [Search and query](/docs/stack/search) features.

## Learn more

* [Redis Sorted Sets Explained](https://www.youtube.com/watch?v=MUKlxdBQZ7g) is an entertaining introduction to sorted sets in Redis.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) explores Redis sorted sets in detail.
