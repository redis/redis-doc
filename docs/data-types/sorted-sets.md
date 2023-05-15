---
title: "Redis sorted sets"
linkTitle: "Sorted sets"
weight: 50
description: >
    Introduction to Redis sorted sets
---

A Redis sorted set is a collection of unique strings (members) ordered by an associated score.
The score is a double-precision floating point number.
When more than one string has the same score, the strings are ordered lexicographically.
Some use cases for sorted sets include:

* Leaderboards. For example, you can use sorted sets to easily maintain ordered lists of the highest scores in a massive online game.
* Rate limiters. In particular, you can use a sorted set to build a sliding window rate limiter to prevent excessive API requests.
* Secondary Indexing. See the [Secondary indexing](/docs/manual/patterns/indexes) page for more information.

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
If you need to index and query your data, consider [RediSearch](/docs/stack/search) and [RedisJSON](/docs/stack/json).

## Learn more

* [Redis Sorted Sets Explained](https://www.youtube.com/watch?v=MUKlxdBQZ7g) is an entertaining introduction to sorted sets in Redis.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) explores Redis sorted sets in detail.
