---
title: Introduction to Redis
linkTitle: "About"
weight: 10
description: Learn about the Redis open source project
aliases:
  - /topics/introduction
  - /buzz
---

Redis is an open source (BSD licensed), in-memory __data structure store__ used as a database, cache, message broker, and streaming engine. Redis provides [data structures](/docs/data-types/) such as
[strings](/docs/data-types/strings/), [hashes](/docs/data-types/hashes/), [lists](/docs/data-types/lists/), [sets](/docs/data-types/sets/), [sorted sets](/docs/data-types/sorted-sets/) with range queries, [bitmaps](/docs/data-types/bitmaps/), [hyperloglogs](/docs/data-types/hyperloglogs/), [geospatial indexes](/docs/data-types/geospatial/), and [streams](/docs/data-types/streams/). Redis has built-in [replication](/topics/replication), [Lua scripting](/commands/eval), [LRU eviction](/docs/reference/eviction/), [transactions](/topics/transactions), and different levels of [on-disk persistence](/topics/persistence), and provides high availability via [Redis Sentinel](/topics/sentinel) and automatic partitioning with [Redis Cluster](/topics/cluster-tutorial).

You can run __atomic operations__
on these types, like [appending to a string](/commands/append);
[incrementing the value in a hash](/commands/hincrby); [pushing an element to a
list](/commands/lpush); [computing set intersection](/commands/sinter),
[union](/commands/sunion) and [difference](/commands/sdiff);
or [getting the member with highest ranking in a sorted set](/commands/zrange).

To achieve top performance, Redis works with an
**in-memory dataset**. Depending on your use case, Redis can persist your data either
by periodically [dumping the dataset to disk](/topics/persistence#snapshotting)
or by [appending each command to a disk-based log](/topics/persistence#append-only-file). You can also disable persistence if you just need a feature-rich, networked, in-memory cache.

Redis supports [asynchronous replication](/topics/replication), with fast non-blocking synchronization and auto-reconnection with partial resynchronization on net split.

Redis also includes:

* [Transactions](/topics/transactions)
* [Pub/Sub](/topics/pubsub)
* [Lua scripting](/commands/eval)
* [Keys with a limited time-to-live](/commands/expire)
* [LRU eviction of keys](/docs/reference/eviction)
* [Automatic failover](/topics/sentinel)

You can use Redis from [most programming languages](/clients).

Redis is written in **ANSI C** and works on most POSIX systems like Linux,
\*BSD, and Mac OS X, without external dependencies. Linux and OS X are the two operating systems where Redis is developed and tested the most, and we **recommend using Linux for deployment**. Redis may work in Solaris-derived systems like SmartOS, but support is *best effort*.
There is no official support for Windows builds.

<hr>