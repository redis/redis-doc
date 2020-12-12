Introduction to Redis
===

Redis is an open source (BSD licensed), in-memory **data structure store**, used as a database, cache, and message broker. Redis provides data structures such as
[strings](/topics/data-types-intro#strings), [hashes](/topics/data-types-intro#hashes), [lists](/topics/data-types-intro#lists), [sets](/topics/data-types-intro#sets), [sorted sets](/topics/data-types-intro#sorted-sets) with range queries, [bitmaps](/topics/data-types-intro#bitmaps), [hyperloglogs](/topics/data-types-intro#hyperloglogs), [geospatial indexes](/commands/geoadd), and [streams](/topics/streams-intro). Redis has built-in [replication](/topics/replication), [Lua scripting](/commands/eval), [LRU eviction](/topics/lru-cache), [transactions](/topics/transactions), and different levels of [on-disk persistence](/topics/persistence), and provides high availability via [Redis Sentinel](/topics/sentinel) and automatic partitioning with [Redis Cluster](/topics/cluster-tutorial).

You can run **atomic operations**
on these types, like [appending to a string](/commands/append);
[incrementing the value in a hash](/commands/hincrby); [pushing an element to a
list](/commands/lpush); [computing set intersection](/commands/sinter),
[union](/commands/sunion) and [difference](/commands/sdiff);
or [getting the member with highest ranking in a sorted
set](/commands/zrangebyscore).

To achieve top performance, Redis works with an
**in-memory dataset**. Depending on your use case, you can persist your data either
by periodically [dumping the dataset to disk](/topics/persistence#snapshotting)
 or by [appending each command to a
disk-based log](/topics/persistence#append-only-file). You can also disable persistence if you just need a feature-rich, networked, in-memory cache.

Redis also supports [asynchronous replication](/topics/replication), with very fast non-blocking first synchronization, auto-reconnection with partial resynchronization on net split.

Other features include:

* [Transactions](/topics/transactions)
* [Pub/Sub](/topics/pubsub)
* [Lua scripting](/commands/eval)
* [Keys with a limited time-to-live](/commands/expire)
* [LRU eviction of keys](/topics/lru-cache)
* [Automatic failover](/topics/sentinel)

You can use Redis from [most programming languages](/clients).

Redis is written in **ANSI C** and works in most POSIX systems like Linux,
\*BSD, and OS X, without external dependencies. Linux and OS X are the two operating systems where Redis is developed and tested the most, and we **recommend using Linux for deployment**. Redis may work in Solaris-derived systems like SmartOS, but the support is *best effort*.
There is no official support for Windows builds.
