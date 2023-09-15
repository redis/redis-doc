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

Let's start with a simple example, we'll add all our racers and the score they got in the first race:

{{< clients-example ss_tutorial zadd >}}
> ZADD racer_scores 10 "Norem"
(integer) 1
> ZADD racer_scores 12 "Castilla"
(integer) 1
> ZADD racer_scores 8 "Sam-Bodden" 10 "Royce" 6 "Ford" 14 "Prickett"
(integer) 4
{{ /clients-example> }}


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
all, it's already all sorted. Note that the `ZRANGE` order is low to high, while the `ZREVRANGE` order is high to low:

{{< clients-example ss_tutorial zrange >}}
> ZRANGE racer_scores 0 -1
1) "Ford"
2) "Sam-Bodden"
3) "Norem"
4) "Royce"
5) "Castilla"
6) "Prickett"
> ZREVRANGE racer_scores 0 -1
1) "Prickett"
2) "Castilla"
3) "Royce"
4) "Norem"
5) "Sam-Bodden"
6) "Ford"
{{ /clients-example> }}

Note: 0 and -1 means from element index 0 to the last element (-1 works
here just as it does in the case of the `LRANGE` command).

It is possible to return scores as well, using the `WITHSCORES` argument:

{{< clients-example ss_tutorial zrange_withscores >}}
> ZRANGE racer_scores 0 -1 withscores
 1) "Ford"
 2) "6"
 3) "Sam-Bodden"
 4) "8"
 5) "Norem"
 6) "10"
 7) "Royce"
 8) "10"
 9) "Castilla"
10) "12"
11) "Prickett"
12) "14"
{{ /clients-example> }}

### Operating on ranges

Sorted sets are more powerful than this. They can operate on ranges.
Let's get all the racers with 10 or fewer points. We
use the `ZRANGEBYSCORE` command to do it:

{{< clients-example ss_tutorial zrangebyscore >}}
> ZRANGEBYSCORE racer_scores -inf 10
1) "Ford"
2) "Sam-Bodden"
3) "Norem"
4) "Royce"
{{ /clients-example> }}

We asked Redis to return all the elements with a score between negative
infinity and 10 (both extremes are included).

To remove an element we'd simply call `ZREM` with the racers name. 
It's also possible to remove ranges of elements. Let's remove racer Castilla along with all
the racers with strictly fewer than 10 points:

{{< clients-example ss_tutorial zremrangebyscore >}}
> ZREM racer_scores "Castilla"
(integer) 1
> ZREMRANGEBYSCORE racer_scores -inf 9
(integer) 2
> ZRANGE racer_scores 0 -1
1) "Norem"
2) "Royce"
3) "Prickett"
{{ /clients-example> }}

`ZREMRANGEBYSCORE` is perhaps not the best command name,
but it can be very useful, and returns the number of removed elements.

Another extremely useful operation defined for sorted set elements
is the get-rank operation. It is possible to ask what is the
position of an element in the set of the ordered elements. 
The `ZREVRANK` command is also available in order to get the rank, considering
the elements sorted a descending way.

{{< clients-example ss_tutorial zrank >}}
> ZRANK racer_scores "Norem"
(integer) 0
> ZREVRANK racer_scores "Norem"
(integer) 3
{{ /clients-example> }}

### Lexicographical scores

In version Redis 2.8, a new feature was introduced that allows
getting ranges lexicographically, assuming elements in a sorted set are all
inserted with the same identical score (elements are compared with the C
`memcmp` function, so it is guaranteed that there is no collation, and every
Redis instance will reply with the same output).

The main commands to operate with lexicographical ranges are `ZRANGEBYLEX`,
`ZREVRANGEBYLEX`, `ZREMRANGEBYLEX` and `ZLEXCOUNT`.

For example, let's add again our list of famous hackers, but this time
use a score of zero for all the elements. We'll see that because of the sorted sets ordering rules, they are already sorted lexicographically. Using `ZRANGEBYLEX` we can ask for lexicographical ranges:

{{< clients-example ss_tutorial zadd_lex >}}
> ZADD racer_scores 0 "Norem" 0 "Sam-Bodden" 0 "Royce" 0 "Castilla" 0 "Prickett" 0 "Ford"
(integer) 3
> ZRANGE racer_scores 0 -1
1) "Castilla"
2) "Ford"
3) "Norem"
4) "Prickett"
5) "Royce"
6) "Sam-Bodden"
> ZRANGEBYLEX racer_scores [A [L
1) "Castilla"
2) "Ford"
{{ /clients-example> }}

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

* There are two ways we can use a sorted set to represent a leaderbaord. If we know a racers new score, we can update it directly via the `ZADD` command. However if we want to add points to an existing score, we can use the `ZINCRBY` command.
{{< clients-example ss_tutorial leaderboard >}}
> ZADD racer_scores 100 "Wood"
(integer) 1
> ZADD racer_scores 100 "Henshaw"
(integer) 1
> ZADD racer_scores 150 "Henshaw"
(integer) 0
> ZINCRBY racer_scores 50 "Wood"
"150"
> ZINCRBY racer_scores 50 "Henshaw"
"200"
{{ /clients-example> }}

You'll see that `ZADD` returns 0 when the member already exists, and the score is updated while `ZINCRBY` returns the new score. The score for racer Henshaw went from 100, was changed to 150 with no regard for what score was there before, and then was incremented by 50 to 200.

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
