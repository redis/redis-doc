Welcome to Redis!
=================

Redis is an advanced **key-value store**. Keys can contain different
**data structures**, such as [strings](/topics/data-types#strings),
[hashes](/topics/data-types#hashes),
[lists](/topics/data-types#lists), [sets](/topics/data-types#sets) and
[sorted sets](/topics/data-types#sorted-sets). You can run **atomic operations**
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

Other features include a simple [check-and-set
mechanism](/topics/transactions), [pub/sub](/topics/pubsub)
and configuration settings to make Redis behave like a
[cache](/topics/cache).

You can use Redis from [most programming languages](/clients) out there. 

Redis is written in **ANSI C** and works in most POSIX systems like Linux,
\*BSD, OS X and Solaris without external dependencies. Redis is **free
software** released under the very liberal BSD license. There
is no official support for Windows builds, although you may
have [some](http://code.google.com/p/redis/issues/detail?id=34)
[options](https://github.com/dmajkic/redis).
