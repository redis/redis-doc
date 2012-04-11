# FAQ

## Why Redis is different compared to other key-value stores?

There are two main reasons.

* Redis is a different evolution path in the key-value DBs where values can contain more complex data types, with atomic operations defined against those data types. Redis data types are closely related to fundamental data structures and are exposed to the programmer as such, without additional abstraction layers.
* Redis is an in-memory but persistent on disk database, so it represents a different trade off where very high write and read speed is achieved with the limitation of data sets that can't be larger than memory. Another advantage of
in memory databases is that the memory representation of complex data structure
is much simpler to manipulate compared to the same data structure on disk, so
Redis can do a lot with little internal complexity. At the same time an on-disk
format that does not need to be suitable for random access is compact and
always generated in an append-only fashion.

## What's the Redis memory footprint?

To give you an example: 1 Million keys with the key being the natural numbers from
0 to 999999 and the string "Hello World" as value use 100MB on my Intel MacBook
(32bit). Note that the same data stored linearly in an unique string takes
something like 16MB, this is expected because with small keys and values there
is a lot of overhead. Memcached will perform similarly, but a bit better as
Redis has more overhead (type information, refcount and so forth) to represent
different kinds of objects.

With large keys/values the ratio is much better of course.

64 bit systems will use considerably more memory than 32 bit systems to store the same keys, especially if the keys and values are small, this is because pointers takes 8 bytes in 64 bit systems. But of course the advantage is that you can
have a lot of memory in 64 bit systems, so in order to run large Redis servers a 64 bit system is more or less required.

## I like Redis high level operations and features, but I don't like that it takes everything in memory and I can't have a dataset larger the memory. Plans to change this?

In the past the Redis developers experimented with Virtual Memory and other systems in order to allow larger than RAM datasets, but after all we are very happy if we can do one thing well: data served from memory, disk used for storage. So for now there are no plans to create an on disk backend for Redis. Most of what
Redis is, after all, is a direct result of its current design.

However many large users solved the issue of large datasets distributing among multiple Redis nodes, using client-side hashing. **Craigslist** and **Groupon** are two examples.

At the same time Redis Cluster, an automatically distributed and fault tolerant
implementation of a Redis subset, is a work in progress, and may be a good
solution for many use cases.

## If my dataset is too big for RAM and I don't want to use consistent hashing or other ways to distribute the dataset across different nodes, what I can do to use Redis anyway?

A possible solution is to use both an on disk DB (MySQL or others) and Redis
at the same time, basically take the state on Redis (metadata, small but often written info), and all the other things that get accessed very
frequently: user auth tokens, Redis Lists with chronologically ordered IDs of
the last N-comments, N-posts, and so on. Then use MySQL (or any other) as a simple storage engine for larger data, that is just create a table with an auto-incrementing ID as primary key and a large BLOB field as data field. Access MySQL data only by primary key (the ID). The application will run the high traffic queries against Redis but when there is to take the big data will ask MySQL for
specific resources IDs.

## Is there something I can do to lower the Redis memory usage?

If you can use Redis 32 bit instances, and make good use of small hashes,
lists, sorted sets, and sets of integers, since Redis is able to represent
those data types in the special case of a few elements in a much more compact
way.

## What happens if Redis runs out of memory?

With modern operating systems malloc() returning NULL is not common, usually
the server will start swapping and Redis performances will degrade so
you'll probably notice there is something wrong.

The INFO command will report the amount of memory Redis is using so you can
write scripts that monitor your Redis servers checking for critical conditions.

You can also use the "maxmemory" option in the config file to put a limit to
the memory Redis can use. If this limit is reached Redis will start to reply
with an error to write commands (but will continue to accept read-only
commands), or you can configure it to evict keys when the max memory limit
is reached.

## Background saving is failing with a fork() error under Linux even if I've a lot of free RAM!

Short answer: `echo 1 > /proc/sys/vm/overcommit_memory` :)

And now the long one:

Redis background saving schema relies on the copy-on-write semantic of fork in
modern operating systems: Redis forks (creates a child process) that is an
exact copy of the parent. The child process dumps the DB on disk and finally
exits. In theory the child should use as much memory as the parent being a
copy, but actually thanks to the copy-on-write semantic implemented by most
modern operating systems the parent and child process will _share_ the common
memory pages. A page will be duplicated only when it changes in the child or in
the parent. Since in theory all the pages may change while the child process is
saving, Linux can't tell in advance how much memory the child will take, so if
the `overcommit_memory` setting is set to zero fork will fail unless there is
as much free RAM as required to really duplicate all the parent memory pages,
with the result that if you have a Redis dataset of 3 GB and just 2 GB of free
memory it will fail.

Setting `overcommit_memory` to 1 says Linux to relax and perform the fork in a
more optimistic allocation fashion, and this is indeed what you want for Redis.

A good source to understand how Linux Virtual Memory work and other
alternatives for `overcommit_memory` and `overcommit_ratio` is this classic
from Red Hat Magazine, ["Understanding Virtual Memory"][redhatvm].

[redhatvm]: http://www.redhat.com/magazine/001nov04/features/vm/

## Are Redis on disk snapshots atomic?

Yes, redis background saving process is always fork(2)ed when the server is
outside of the execution of a command, so every command reported to be atomic
in RAM is also atomic from the point of view of the disk snapshot.

## Redis is single threaded, how can I exploit multiple CPU / cores?

Simply start multiple instances of Redis in the same box and
treat them as different servers. At some point a single box may not be
enough anyway, so if you want to use multiple CPUs you can start thinking
at some way to shard earlier. However note that using pipelining Redis running
on an average Linux system can deliver even 500k requests per second, so
if your application mainly uses O(N) or O(log(N)) commands it is hardly
going to use too much CPU.

In Redis there are client libraries such Redis-rb (the Ruby client) and
Predis (one of the most used PHP clients) that are able to handle multiple
servers automatically using _consistent hashing_.

## What is the maximum number of keys a single Redis instance can hold? and what the max number of elements in a List, Set, Ordered Set?

In theory Redis can handle up to 2^32 keys, and was tested in practice to
handle at least 250 million of keys per instance. We are working in order to
experiment with larger values.

Every list, set, and ordered set, can hold 2^32 elements.

In other words your limit is likely the available memory in your system.

## What Redis means actually?

It means REmote DIctionary Server.

## Why did you started the Redis project?

Originally Redis was started in order to scale [LLOOGG][lloogg]. But after I got the basic server working I liked the idea to share the work with other guys, and Redis was turned into an open source project.

[lloogg]: http://lloogg.com
