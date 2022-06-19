---
title: "Redis FAQ"
linkTitle: "FAQ"
weight: 100
description: >
    Commonly asked questions when getting started with Redis
aliases:
    - /docs/getting-started/faq
---
## How is Redis different from other key-value stores?

* Redis has a different evolution path in the key-value DBs where values can contain more complex data types, with atomic operations defined on those data types. Redis data types are closely related to fundamental data structures and are exposed to the programmer as such, without additional abstraction layers.
* Redis is an in-memory but persistent on disk database, so it represents a different trade off where very high write and read speed is achieved with the limitation of data sets that can't be larger than memory. Another advantage of
in-memory databases is that the memory representation of complex data structures
is much simpler to manipulate compared to the same data structures on disk, so
Redis can do a lot with little internal complexity. At the same time the
two on-disk storage formats (RDB and AOF) don't need to be suitable for random
access, so they are compact and always generated in an append-only fashion
(Even the AOF log rotation is an append-only operation, since the new version
is generated from the copy of data in memory). However this design also involves
different challenges compared to traditional on-disk stores. Being the main data
representation on memory, Redis operations must be carefully handled to make sure
there is always an updated version of the data set on disk.

## What's the Redis memory footprint?

To give you a few examples (all obtained using 64-bit instances):

* An empty instance uses ~ 3MB of memory.
* 1 Million small Keys -> String Value pairs use ~ 85MB of memory.
* 1 Million Keys -> Hash value, representing an object with 5 fields, use ~ 160 MB of memory.

Testing your use case is trivial. Use the `redis-benchmark` utility to generate random data sets then check the space used with the `INFO memory` command.

64-bit systems will use considerably more memory than 32-bit systems to store the same keys, especially if the keys and values are small. This is because pointers take 8 bytes in 64-bit systems. But of course the advantage is that you can
have a lot of memory in 64-bit systems, so in order to run large Redis servers a 64-bit system is more or less required. The alternative is sharding.

## Why does Redis keep its entire dataset in memory?

In the past the Redis developers experimented with Virtual Memory and other systems in order to allow larger than RAM datasets, but after all we are very happy if we can do one thing well: data served from memory, disk used for storage. So for now there are no plans to create an on disk backend for Redis. Most of what
Redis is, after all, a direct result of its current design.

If your real problem is not the total RAM needed, but the fact that you need
to split your data set into multiple Redis instances, please read the
[partitioning page](/topics/partitioning) in this documentation for more info.

Redis Ltd., the company sponsoring Redis development, has developed a
"Redis on Flash" solution that uses a mixed RAM/flash approach for
larger data sets with a biased access pattern. You may check their offering
for more information, however this feature is not part of the open source Redis
code base.

## Can you use Redis with a disk-based database?

Yes, a common design pattern involves taking very write-heavy small data
in Redis (and data you need the Redis data structures to model your problem
in an efficient way), and big *blobs* of data into an SQL or eventually
consistent on-disk database. Similarly sometimes Redis is used in order to
take in memory another copy of a subset of the same data stored in the on-disk
database. This may look similar to caching, but actually is a more advanced model
since normally the Redis dataset is updated together with the on-disk DB dataset,
and not refreshed on cache misses.

## How can I reduce Redis' overall memory usage?

If you can, use Redis 32 bit instances. Also make good use of small hashes,
lists, sorted sets, and sets of integers, since Redis is able to represent
those data types in the special case of a few elements in a much more compact
way. There is more info in the [Memory Optimization page](/topics/memory-optimization).

## What happens if Redis runs out of memory?

Redis has built-in protections allowing the users to set a max limit on memory
usage, using the `maxmemory` option in the configuration file to put a limit
to the memory Redis can use. If this limit is reached, Redis will start to reply
with an error to write commands (but will continue to accept read-only
commands).

You can also configure Redis to evict keys when the max memory limit
is reached. See the [eviction policy docs] for more information on this.

## Background saving fails with a fork() error on Linux?

Short answer: `echo 1 > /proc/sys/vm/overcommit_memory` :)

And now the long one:

The Redis background saving schema relies on the copy-on-write semantic of the `fork` system call in
modern operating systems: Redis forks (creates a child process) that is an
exact copy of the parent. The child process dumps the DB on disk and finally
exits. In theory the child should use as much memory as the parent being a
copy, but actually thanks to the copy-on-write semantic implemented by most
modern operating systems the parent and child process will _share_ the common
memory pages. A page will be duplicated only when it changes in the child or in
the parent. Since in theory all the pages may change while the child process is
saving, Linux can't tell in advance how much memory the child will take, so if
the `overcommit_memory` setting is set to zero the fork will fail unless there is
as much free RAM as required to really duplicate all the parent memory pages.
If you have a Redis dataset of 3 GB and just 2 GB of free
memory it will fail.

Setting `overcommit_memory` to 1 tells Linux to relax and perform the fork in a
more optimistic allocation fashion, and this is indeed what you want for Redis.

You can refer to the [proc(5)][proc5] man page for explanations of the
available values.

[proc5]: http://man7.org/linux/man-pages/man5/proc.5.html

## Are Redis on-disk snapshots atomic?

Yes, the Redis background saving process is always forked when the server is
outside of the execution of a command, so every command reported to be atomic
in RAM is also atomic from the point of view of the disk snapshot.

## How can Redis use multiple CPUs or cores?

It's not very frequent that CPU becomes your bottleneck with Redis, as usually Redis is either memory or network bound.
For instance, when using pipelining a Redis instance running on an average Linux system can deliver 1 million requests per second, so if your application mainly uses O(N) or O(log(N)) commands, it is hardly going to use too much CPU.

However, to maximize CPU usage you can start multiple instances of Redis in
the same box and treat them as different servers. At some point a single
box may not be enough anyway, so if you want to use multiple CPUs you can
start thinking of some way to shard earlier.

You can find more information about using multiple Redis instances in the [Partitioning page](/topics/partitioning).

As of version 4.0, Redis has started implementing threaded actions. For now this is limited to deleting objects in the background and blocking commands implemented via Redis modules. For subsequent releases, the plan is to make Redis more and more threaded.

## What is the maximum number of keys a single Redis instance can hold? What is the maximum number of elements in a Hash, List, Set, and Sorted Set?

Redis can handle up to 2^32 keys, and was tested in practice to
handle at least 250 million keys per instance.

Every hash, list, set, and sorted set, can hold 2^32 elements.

In other words your limit is likely the available memory in your system.

## Why does my replica have a different number of keys its master instance?

If you use keys with limited time to live (Redis expires) this is normal behavior. This is what happens:

* The primary generates an RDB file on the first synchronization with the replica.
* The RDB file will not include keys already expired in the primary but which are still in memory.
* These keys are still in the memory of the Redis primary, even if logically expired. They'll be considered non-existent, and their memory will be reclaimed later, either incrementally or explicitly on access. While these keys are not logically part of the dataset, they are accounted for in the `INFO` output and in the `DBSIZE` command.
* When the replica reads the RDB file generated by the primary, this set of keys will not be loaded.

Because of this, it's common for users with many expired keys to see fewer keys in the replicas. However, logically, the primary and replica will have the same content.

## Where does the name "Redis" come from?

Redis is an acronym that stands for **RE**mote **DI**ctionary **S**erver.

## Why did Salvatore Sanfilippo start the Redis project?

Salvatore originally created Redis to scale [LLOOGG](https://github.com/antirez/lloogg), a real-time log analysis tool. But after getting the basic Redis server working, he decided to share the work with other people and turn Redis into an open source project.

## How is Redis pronounced?

"Redis" (/ˈrɛd-ɪs/) is pronounced like the word "red" plus the word "kiss" without the "k".
