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

## Tutorial

The [`SADD`](/commands/sadd) command adds new elements to a set. It's also possible
to do a number of other operations against sets like testing if a given element
already exists, performing the intersection, union or difference between
multiple sets, and so forth.

    > sadd myset 1 2 3
    (integer) 3
    > smembers myset
    1. 3
    2. 1
    3. 2

Here I've added three elements to my set and told Redis to return all the
elements. As you can see they are not sorted -- Redis is free to return the
elements in any order at every call, since there is no contract with the
user about element ordering.

Redis has commands to test for membership. For example, checking if an element exists:

    > sismember myset 3
    (integer) 1
    > sismember myset 30
    (integer) 0

"3" is a member of the set, while "30" is not.

Sets are good for expressing relations between objects.
For instance we can easily use sets in order to implement tags.

A simple way to model this problem is to have a set for every object we
want to tag. The set contains the IDs of the tags associated with the object.

One illustration is tagging news articles.
If article ID 1000 is tagged with tags 1, 2, 5 and 77, a set
can associate these tag IDs with the news item:

    > sadd news:1000:tags 1 2 5 77
    (integer) 4

We may also want to have the inverse relation as well: the list
of all the news tagged with a given tag:

    > sadd tag:1:news 1000
    (integer) 1
    > sadd tag:2:news 1000
    (integer) 1
    > sadd tag:5:news 1000
    (integer) 1
    > sadd tag:77:news 1000
    (integer) 1

To get all the tags for a given object is trivial:

    > smembers news:1000:tags
    1. 5
    2. 1
    3. 77
    4. 2

Note: in the example we assume you have another data structure, for example
a Redis hash, which maps tag IDs to tag names.

There are other non trivial operations that are still easy to implement
using the right Redis commands. For instance we may want a list of all the
objects with the tags 1, 2, 10, and 27 together. We can do this using
the [`SINTER`](/commands/sinter) command, which performs the intersection between different
sets. We can use:

    > sinter tag:1:news tag:2:news tag:10:news tag:27:news
    ... results here ...

In addition to intersection you can also perform
unions, difference, extract a random element, and so forth.

The command to extract an element is called [`SPOP`](/commands/spop), and is handy to model
certain problems. For example in order to implement a web-based poker game,
you may want to represent your deck with a set. Imagine we use a one-char
prefix for (C)lubs, (D)iamonds, (H)earts, (S)pades:

    > sadd deck C1 C2 C3 C4 C5 C6 C7 C8 C9 C10 CJ CQ CK
      D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 DJ DQ DK H1 H2 H3
      H4 H5 H6 H7 H8 H9 H10 HJ HQ HK S1 S2 S3 S4 S5 S6
      S7 S8 S9 S10 SJ SQ SK
    (integer) 52

Now we want to provide each player with 5 cards. The [`SPOP`](/commands/spop) command
removes a random element, returning it to the client, so it is the
perfect operation in this case.

However if we call it against our deck directly, in the next play of the
game we'll need to populate the deck of cards again, which may not be
ideal. So to start, we can make a copy of the set stored in the `deck` key
into the `game:1:deck` key.

This is accomplished using [`SUNIONSTORE`](/commands/sunionstore), which normally performs the
union between multiple sets, and stores the result into another set.
However, since the union of a single set is itself, I can copy my deck
with:

    > sunionstore game:1:deck deck
    (integer) 52

Now I'm ready to provide the first player with five cards:

    > spop game:1:deck
    "C6"
    > spop game:1:deck
    "CQ"
    > spop game:1:deck
    "D1"
    > spop game:1:deck
    "CJ"
    > spop game:1:deck
    "SJ"

One pair of jacks, not great...

This is a good time to introduce the set command that provides the number
of elements inside a set. This is often called the *cardinality of a set*
in the context of set theory, so the Redis command is called [`SCARD`](/commands/scard).

    > scard game:1:deck
    (integer) 47

The math works: 52 - 5 = 47.

When you need to just get random elements without removing them from the
set, there is the [`SRANDMEMBER`](/commands/srandmember) command suitable for the task. It also features
the ability to return both repeating and non-repeating elements.

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
