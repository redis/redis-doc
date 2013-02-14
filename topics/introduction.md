Introduction to Redis
===

Redis is an open source (BSD licensed), advanced **key-value store**.  It
is often referred to as a **data structure server** since
keys can contain [strings](/topics/data-types#strings),
[hashes](/topics/data-types#hashes), [lists](/topics/data-types#lists),
[sets](/topics/data-types#sets) and [sorted
sets](/topics/data-types#sorted-sets).

You can run **atomic operations**
on these types, like [appending to a string](/commands/append);
[incrementing the value in a hash](/commands/hincrby); [pushing to a
list](/commands/lpush); [computing set intersection](/commands/sinter),
[union](/commands/sunion) and [difference](/commands/sdiff);
or [getting the member with highest ranking in a sorted
set](/commands/zrangebyscore).

In order to achieve its outstanding performance, Redis works with an
**in-memory dataset**. Depending on your use case, you can persist it either
by [dumping the dataset to disk](/topics/persistence#snapshotting)
every once in a while, or by [appending each command to a
log](/topics/persistence#append-only-file).

Redis also supports trivial-to-setup [master-slave
replication](/topics/replication), with very fast non-blocking first
synchronization, auto-reconnection on net split and so forth.

Other features include [Transactions](/topics/transactions),
[Pub/Bub](/topics/pubsub),
[Lua scripting](/commands/eval),
[Keys with a limited time-to-live](/commands/expire),
and configuration settings to make Redis behave like a cache.

You can use Redis from [most programming languages](/clients) out there. 

Redis is written in **ANSI C** and works in most POSIX systems like Linux,
\*BSD, OS X without external dependencies. Linux and OSX are the two operating systems where Redis is developed and more tested, and we **recommend using Linux for deploying**. Redis may work in Solaris-derived systems like SmartOS, but the support is *best effort*. There
is no official support for Windows builds, but Microsoft develops and
maintains a [Win32-64 experimental version of Redis](https://github.com/MSOpenTech/redis).
