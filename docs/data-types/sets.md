---
title: "Redis sets"
linkTitle: "Sets"
weight: 30
description: >
    Introduction to Redis sets
---

A Redis set is an unordered collection of unique strings (members).
You can use Redis sets to efficiently:

* Track unique items (e.g., track all unique IP addresses accessing a given blog post).
* Represent relations (e.g., the set of all users with a given role).
* Perform common set operations such as intersection, unions, and differences.

## Examples

* Store the set of favorited book IDs for users 123 and 456:
```
> SADD user:123:favorites 347
(integer) 1
> SADD user:123:favorites 561
(integer) 1
> SADD user:123:favorites 742
(integer) 1
> SADD user:456:favorites 561
(integer) 1
```

* Check whether user 123 likes books 742 and 299
```
> SISMEMBER user:123:favorites 742
(integer) 1
> SISMEMBER user:123:favorites 299
(integer) 0
```

* Do user 123 and 456 have any favorite books in common?
```
> SINTER user:123:favorites user:456:favorites
1) "561"
```

* How many books has user 123 favorited?
```
> SCARD user:123:favorites
(integer) 3
```

## Limits

The max size of a Redis set is 2^32 - 1 (4,294,967,295) members.

## Basic commands

* `SADD` adds a new member to a set.
* `SREM` removes the specified member from the set.
* `SISMEMBER` tests a string for set membership.
* `SINTER` returns the set of members that two or more sets have in common (i.e., the intersection).
* `SCARD` returns the size (a.k.a. cardinality) of a set.

See the [complete list of set commands](https://redis.io/commands/?group=set).

## Performance

Most set operations, including adding, removing, and checking whether an item is a set member, are O(1).
This means that they're highly efficient.
However, for large sets with hundreds of thousands of members or more, you should exercise caution when running the `SMEMBERS` command.
This command is O(n) and returns the entire set in a single response. 
As an alternative, consider the `SSCAN`, which lets you retrieve all members of a set iteratively.

## Alternatives

Sets membership checks on large datasets (or on streaming data) can use a lot of memory.
If you're concerned about memory usage and don't need perfect precision, consider a [Bloom filter or Cuckoo filter](/docs/stack/bloom) as an alternative to a set.

Redis sets are frequently used as a kind of index.
If you need to index and query your data, consider [RediSearch](/docs/stack/search) and [RedisJSON](/docs/stack/json).

## Learn more

* [Redis Sets Explained](https://www.youtube.com/watch?v=PKdCppSNTGQ) and [Redis Sets Elaborated](https://www.youtube.com/watch?v=aRw5ME_5kMY) are two short but thorough video explainers covering Redis sets.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) explores Redis sets in detail.
