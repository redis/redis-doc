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

## Basic commands

* `SADD` adds a new member to a set.
* `SREM` removes the specified member from the set.
* `SISMEMBER` tests a string for set membership.
* `SINTER` returns the set of members that two or more sets have in common (i.e., the intersection).
* `SCARD` returns the size (a.k.a. cardinality) of a set.

See the [complete list of set commands](https://redis.io/commands/?group=set).

## Examples

* Store the sets of bikes racing in France and the USA. Note that 
if you add a member that already exists, it will be ignored. 
{{< clients-example sets_tutorial sadd >}}
> SADD bikes:racing:france bike:1
(integer) 1
> SADD bikes:racing:france bike:1
(integer) 0
> SADD bikes:racing:france bike:2 bike:3
(integer) 2
> SADD bikes:racing:usa bike:1 bike:4
(integer) 2
{{< /clients-example >}}

* Check whether bike:1 or bike:2 are racing in the US.
{{< clients-example sets_tutorial sismember >}}
> SISMEMBER bikes:racing:usa bike:1
(integer) 1
> SISMEMBER bikes:racing:usa bike:2
(integer) 0
{{< /clients-example >}}

* Which bikes are competing in both races?
{{< clients-example sets_tutorial sinter >}}
> SINTER bikes:racing:france bikes:racing:usa
1) "bike:1"
{{< /clients-example >}}

* How many bikes are racing in France?
{{< clients-example sets_tutorial scard >}}
> SCARD bikes:racing:france
(integer) 3
{{< /clients-example >}}
## Tutorial

The `SADD` command adds new elements to a set. It's also possible
to do a number of other operations against sets like testing if a given element
already exists, performing the intersection, union or difference between
multiple sets, and so forth.

{{< clients-example sets_tutorial sadd_smembers >}}
> SADD bikes:racing:france bike:1 bike:2 bike:3
(integer) 3
> SMEMBERS bikes:racing:france
1) bike:3
2) bike:1
3) bike:2
{{< /clients-example >}}

Here I've added three elements to my set and told Redis to return all the
elements. There is no order guarantee with a set. Redis is free to return the
elements in any order at every call.

Redis has commands to test for set membership. These commands can be used on single as well as multiple items:

{{< clients-example sets_tutorial smismember >}}
> SISMEMBER bikes:racing:france bike:1
(integer) 1
> SMISMEMBER bikes:racing:france bike:2 bike:3 bike:4
1) (integer) 1
2) (integer) 1
3) (integer) 0
{{< /clients-example >}}

We can also find the difference between two sets. For instance, we may want
to know which bikes are racing in France but not in the USA:

{{< clients-example sets_tutorial sdiff >}}
> SADD bikes:racing:usa bike:1 bike:4
(integer) 2
> SDIFF bikes:racing:france bikes:racing:usa
1) "bike:3"
2) "bike:2"
{{< /clients-example >}}

There are other non trivial operations that are still easy to implement
using the right Redis commands. For instance we may want a list of all the
bikes racing in France, the USA, and some other races. We can do this using
the `SINTER` command, which performs the intersection between different
sets. In addition to intersection you can also perform
unions, difference, and more. For example 
if we add a third race we can see some of these commands in action:

{{< clients-example sets_tutorial multisets >}}
> SADD bikes:racing:france bike:1 bike:2 bike:3
(integer) 3
> SADD bikes:racing:usa bike:1 bike:4
(integer) 2
> SADD bikes:racing:italy bike:1 bike:2 bike:3 bike:4
(integer) 4
> SINTER bikes:racing:france bikes:racing:usa bikes:racing:italy
1) "bike:1"
> SUNION bikes:racing:france bikes:racing:usa bikes:racing:italy
1) "bike:2"
2) "bike:1"
3) "bike:4"
4) "bike:3"
> SDIFF bikes:racing:france bikes:racing:usa bikes:racing:italy
(empty array)
> SDIFF bikes:racing:france bikes:racing:usa
1) "bike:3"
2) "bike:2"
> SDIFF bikes:racing:usa bikes:racing:france
1) "bike:4"
{{< /clients-example >}}

You'll note that the `SDIFF` command returns an empty array when the
difference between all sets is empty. You'll also note that the order of sets
passed to `SDIFF` matters, since the difference is not commutative.

When you want to remove items from a set, you can use the `SREM` command to
remove one or more items from a set, or you can use the `SPOP` command to
remove a random item from a set. You can also _return_ a random item from a
set without removing it using the `SRANDMEMBER` command:

{{< clients-example sets_tutorial srem >}}
> SADD bikes:racing:france bike:1 bike:2 bike:3 bike:4 bike:5
(integer) 3
> SREM bikes:racing:france bike:1
(integer) 1
> SPOP bikes:racing:france
"bike:3"
> SMEMBERS bikes:racing:france
1) "bike:2"
2) "bike:4"
3) "bike:5"
> SRANDMEMBER bikes:racing:france
"bike:2"
{{< /clients-example >}}

## Limits

The max size of a Redis set is 2^32 - 1 (4,294,967,295) members.

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
If you need to index and query your data, consider the [JSON](/docs/stack/json) data type and the [Search and query](/docs/stack/search) features.

## Learn more

* [Redis Sets Explained](https://www.youtube.com/watch?v=PKdCppSNTGQ) and [Redis Sets Elaborated](https://www.youtube.com/watch?v=aRw5ME_5kMY) are two short but thorough video explainers covering Redis sets.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) explores Redis sets in detail.
