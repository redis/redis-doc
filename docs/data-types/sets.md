---
title: "Redis Sets"
linkTitle: "Sets"
weight: 4
description: >
    Introduction to Redis Sets
---

A Redis set is an unordered collection of unique strings. You can use Redis sets to efficiently:

* Track unique items (e.g., track all unique IP addresses accessing a given blog post)
* Represent relations (e.g., the set of all users with a given role)
* Perform common set operations such as intersection, unions, and differences

## Examples

* Store the set of "favorited" book IDs for users 123 and 456:
```
redis:6379> SADD user:123:favorites 347
(integer) 1
redis:6379> SADD user:123:favorites 561
(integer) 1
redis:6379> SADD user:123:favorites 742
(integer) 1
redis:6379> SADD user:456:favorites 561
(integer) 1
```

* Check whether user 123 likes books 742 and 299
```
redis:6379> SISMEMBER user:123:favorites 742
(integer) 1
redis:6379> SISMEMBER user:123:favorites 299
(integer) 0
```

* Do user 123 and 456 have any favorite books in common?
```
redis:6379> SINTER user:123:favorites user:456:favorites
1) "561"
```

* How many books has user 123 favorited?
```
redis:6379> SCARD user:123:favorites
(integer) 3
```

## Limits

The max size of a Redis set is 2^32 - 1 (4,294,967,295) members.

## Basic commands

* [SADD](/commands/sadd) adds a new member to a set.
* [SREM](/commands/srem) removes the specified member from the set.
* [SISMEMBER](/commands/sismember) tests a string for set membership.
* [SINTER](/commands/sinter) returns the set of members that two or more set have in common (i.e., the intersection).
* [SCARD](/commands/scard) returns the size (a.k.a. cardinality) of a set.

See the [complete list of set commands](https://redis.io/commands/?group=set).

## Performance

Most set operations, including adding, removing, and checking whether an items is a set member, are O(1). This means that they're highly efficient.

For large sets, with hundreds of thousands of members or more, you should exercise some caution when running the [SMEMBERS](/commands/smembers) command. This command is O(n) and returns the entire set in a single response. As an alternative, consider the [SSCAN](/commands/sscan), which lets you retreive all members of a set iteratively.

## Alternatives

Sets membership checks on large datasets (or on streaming data) can use a lot of memory. If you're concerned about memory usage, and don't need perfect precision, consider a [Bloom filter or Cuckoo filter](/docs/stack/bloom) as an alternative to a set.

Redis sets are frequently used as a kind of index. If you need to index and query your data, consider also [RediSearch](/docs/stack/search) and [RedisJSON](/docs/stack/json).

## Learn more

* [Redis Sets Explained](https://www.youtube.com/watch?v=PB5SeOkkxQc) and [Redis Sets Elaborated](https://www.youtube.com/watch?v=aRw5ME_5kMY) are two short but thorough video explainers covering Redis sets.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) explores Redis sets in detail.


