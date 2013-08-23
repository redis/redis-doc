# FAQ

## Why do I need Redis instead of memcachedb, Tokyo Cabinet, ...?

Memcachedb is basically memcached made persistent. Redis is a different
evolution path in the key-value DBs, the idea is that the main advantages of
key-value DBs are retained even without severe loss of comfort of plain
key-value DBs.  So Redis offers more features:

* Keys can store different data types, not just strings. Notably Lists and
  Sets. For example if you want to use Redis as a log storage system for
  different computers every computer can just `RPUSH data to the computer_ID
  key`. Don't want to save more than 1000 log lines per computer? Just issue a
  `LTRIM computer_ID 0 999` command to trim the list after every push.
* Another example is about Sets. Imagine to build a social news site like
  [Reddit][reddit]. Every time a user upvotes a given news you can just add to
  the news_ID_upmods key holding a value of type SET the id of the user that
  did the upmodding. Sets can also be used to index things. Every key can be a
  tag holding a SET with the IDs of all the objects associated to this tag.
  Using Redis set intersection you obtain the list of IDs having all this tags
  at the same time.
* We wrote a [simple Twitter Clone][retwis] using just Redis as database.
  Download the source code from the download section and imagine to write it
  with a plain key-value DB without support for lists and sets... it's *much*
  harder.
* Multiple DBs. Using the SELECT command the client can select different
  datasets. This is useful because Redis provides a MOVE atomic primitive that
  moves a key form a DB to another one, if the target DB already contains such
  a key it returns an error: this basically means a way to perform locking in
  distributed processing.
* *So what is Redis really about?* The User interface with the programmer.
  Redis aims to export to the programmer the right tools to model a wide range
  of problems. *Sets, Lists with O(1) push operation, lrange and ltrim,
  server-side fast intersection between sets, are primitives that allow to
  model complex problems with a key value database*.

[reddit]: http://reddit.com
[retwis]: http://retwis.antirez.com

## Isn't this key-value thing just hype?

I imagine key-value DBs, in the short term future, to be used like you use
memory in a program, with lists, hashes, and so on. With Redis it's like this,
but this special kind of memory containing your data structures is shared,
atomic, persistent.

When we write code it is obvious, when we take data in memory, to use the most
sensible data structure for the work, right? Incredibly when data is put inside
a relational DB this is no longer true, and we create an absurd data model even
if our need is to put data and get this data back in the same order we put it
inside (an ORDER BY is required when the data should be already sorted.
Strange, don't you think?).

Key-value DBs bring this back at home, to create sensible data models and use
the right data structures for the problem we are trying to solve.

## Can I backup a Redis DB while the server is working?

Yes you can. When Redis saves the DB it actually creates a temp file, then
rename(2) that temp file name to the destination file name. So even while the
server is working it is safe to save the database file just with the _cp_ UNIX
command. Note that you can use master-slave replication in order to have
redundancy of data, but if all you need is backups, cp or scp will do the work
pretty well.

## What's the Redis memory footprint?

Worst case scenario: 1 Million keys with the key being the natural numbers from
0 to 999999 and the string "Hello World" as value use 100MB on my Intel MacBook
(32bit). Note that the same data stored linearly in an unique string takes
something like 16MB, this is the norm because with small keys and values there
is a lot of overhead. Memcached will perform similarly.

With large keys/values the ratio is much better of course.

64 bit systems will use much more memory than 32 bit systems to store the same
keys, especially if the keys and values are small, this is because pointers
takes 8 bytes in 64 bit systems. But of course the advantage is that you can
have a lot of memory in 64 bit systems, so to run large Redis servers a 64 bit
system is more or less required.

## I like Redis high level operations and features, but I don't like that it takes everything in memory and I can't have a dataset larger the memory. Plans to change this?

Short answer: If you are using a Redis client that supports consistent hashing
you can distribute the dataset across different nodes. For instance the Ruby
clients supports this feature. There are plans to develop redis-cluster that
basically is a dummy Redis server that is only used in order to distribute the
requests among N different nodes using consistent hashing.

## Why Redis takes the whole dataset in RAM?

Redis takes the whole dataset in memory and writes asynchronously on disk in
order to be very fast, you have the best of both worlds: hyper-speed and
persistence of data, but the price to pay is exactly this, that the dataset
must fit on your computers RAM.

If the data is larger then memory, and this data is stored on disk, what
happens is that the bottleneck of the disk I/O speed will start to ruin the
performances. Maybe not in benchmarks, but once you have real load from
multiple clients with distributed key accesses the data must come from disk,
and the disk is damn slow. Not only, but Redis supports higher level data
structures than the plain values. To implement this things on disk is even
slower.

Redis will always continue to hold the whole dataset in memory because this
days scalability requires to use RAM as storage media, and RAM is getting
cheaper and cheaper. Today it is common for an entry level server to have 16 GB
of RAM! And in the 64-bit era there are no longer limits to the amount of RAM
you can have in theory.

Amazon EC2 now provides instances with 32 or 64 GB of RAM.

## If my dataset is too big for RAM and I don't want to use consistent hashing or other ways to distribute the dataset across different nodes, what I can do to use Redis anyway?

You may try to load a dataset larger than your memory in Redis and see what
happens, basically if you are using a modern Operating System, and you have a
lot of data in the DB that is rarely accessed, the OS's virtual memory
implementation will try to swap rarely used pages of memory on the disk, to
only recall this pages when they are needed. If you have many large values
rarely used this will work. If your DB is big because you have tons of little
values accessed at random without a specific pattern this will not work (at low
level a page is usually 4096 bytes, and you can have different keys/values
stored at a single page. The OS can't swap this page on disk if there are even
few keys used frequently).

Another possible solution is to use both MySQL and Redis at the same time,
basically take the state on Redis, and all the things that get accessed very
frequently: user auth tokens, Redis Lists with chronologically ordered IDs of
the last N-comments, N-posts, and so on. Then use MySQL as a simple storage
engine for larger data, that is just create a table with an auto-incrementing
ID as primary key and a large BLOB field as data field. Access MySQL data only
by primary key (the ID). The application will run the high traffic queries
against Redis but when there is to take the big data will ask MySQL for
specific resources IDs.

Update: it could be interesting to test how Redis performs with datasets larger
than memory if the OS swap partition is in one of this very fast Intel SSD
disks.

## Do you plan to implement Virtual Memory in Redis? Why don't just let the Operating System handle it for you?

Yes, in order to support datasets bigger than RAM there is the plan to
implement transparent Virtual Memory in Redis, that is, the ability to transfer
large values associated to keys rarely used on Disk, and reload them
transparently in memory when this values are requested in some way.

So you may ask why don't let the operating system VM do the work for us. There
are two main reasons: in Redis even a large value stored at a given key, for
instance a 1 million elements list, is not allocated in a contiguous piece of
memory. It's actually *very* fragmented since Redis uses quite aggressive
object sharing and allocated Redis Objects structures reuse.

So you can imagine the memory layout composed of 4096 bytes pages that actually
contain different parts of different large values. Not only, but a lot of
values that are large enough for us to swap out to disk, like a 1024k value, is
just one quarter the size of a memory page, and likely in the same page there
are other values that are not rarely used. So this value wil never be swapped
out by the operating system.  This is the first reason for implementing
application-level virtual memory in Redis.

There is another one, as important as the first. A complex object in memory
like a list or a set is something *10 times bigger* than the same object
serialized on disk. Probably you already noticed how Redis snapshots on disk
are damn smaller compared to the memory usage of Redis for the same objects.
This happens because when data is in memory is full of pointers, reference
counters and other metadata. Add to this malloc fragmentation and need to
return word-aligned chunks of memory and you have a clear picture of what
happens. So this means to have 10 times the I/O between memory and disk than
otherwise needed.

## Is there something I can do to lower the Redis memory usage?

Yes, try to compile it with 32 bit target if you are using a 64 bit box.

If you are using Redis >= 1.3, try using the Hash data type, it can save a lot
of memory.

If you are using hashes or any other type with values bigger than 128 bytes try
also this to lower the RSS usage (Resident Set Size): `EXPORT
MMAP_THRESHOLD=4096`

## I have an empty Redis server but INFO and logs are reporting megabytes of memory in use!

This may happen and it's perfectly okay. Redis objects are small C structures
allocated and freed a lot of times. This costs a lot of CPU so instead of being
freed, released objects are taken into a free list and reused when needed. This
memory is taken exactly by this free objects ready to be reused.

## What happens if Redis runs out of memory?

With modern operating systems malloc() returning NULL is not common, usually
the server will start swapping and Redis performances will be disastrous so
you'll know it's time to use more Redis servers or get more RAM.

The INFO command (work in progress in this days) will report the amount of
memory Redis is using so you can write scripts that monitor your Redis servers
checking for critical conditions.

You can also use the "maxmemory" option in the config file to put a limit to
the memory Redis can use. If this limit is reached Redis will start to reply
with an error to write commands (but will continue to accept read-only
commands).

## Does Redis use more memory running in 64 bit boxes? Can I use 32 bit Redis in 64 bit systems?

Redis uses a lot more memory when compiled for 64 bit target, especially if the
dataset is composed of many small keys and values. Such a database will, for
instance, consume 50 MB of RAM when compiled for the 32 bit target, and 80 MB
for 64 bit! That's a big difference.

You can run 32 bit Redis binaries in a 64 bit Linux and Mac OS X system without
problems. For OS X just use *make 32bit*. For Linux instead, make sure you have
*libc6-dev-i386* installed, then use *make 32bit* if you are using the latest
Git version. Instead for Redis `<= 1.2.2` you have to edit the Makefile and
replace "-arch i386" with "-m32".

If your application is already able to perform application-level sharding, it
is very advisable to run N instances of Redis 32bit against a big 64 bit Redis
box (with more than 4GB of RAM) instead than a single 64 bit instance, as this
is much more memory efficient.

## How much time it takes to load a big database at server startup?

Just an example on normal hardware: It takes about 45 seconds to restore a 2 GB
database on a fairly standard system, no RAID. This can give you some kind of
feeling about the order of magnitude of the time needed to load data when you
restart the server.

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
Beware, this article had 1 and 2 configuration value for `overcommit_memory`
reversed: refer to the [proc(5)][proc5] man page for the right meaning of the
available values.

[redhatvm]: http://www.redhat.com/magazine/001nov04/features/vm/
[proc5]: http://man7.org/linux/man-pages/man5/proc.5.html

## Are Redis on disk snapshots atomic?

Yes, redis background saving process is always fork(2)ed when the server is
outside of the execution of a command, so every command reported to be atomic
in RAM is also atomic from the point of view of the disk snapshot.

## Redis is single threaded, how can I exploit multiple CPU / cores?

Simply start multiple instances of Redis in different ports in the same box and
treat them as different servers! Given that Redis is a distributed database
anyway in order to scale you need to think in terms of multiple computational
units. At some point a single box may not be enough anyway.

In general key-value databases are very scalable because of the property that
different keys can stay on different servers independently.

In Redis there are client libraries such Redis-rb (the Ruby client) that are
able to handle multiple servers automatically using _consistent hashing_. We
are going to implement consistent hashing in all the other major client
libraries. If you use a different language you can implement it yourself
otherwise just hash the key before to SET / GET it from a given server. For
example imagine to have N Redis servers, server-0, server-1, ..., server-N. You
want to store the key "foo", what's the right server where to put "foo" in
order to distribute keys evenly among different servers? Just perform the _crc_
= CRC32("foo"), then _servernum_ = _crc_ % N (the rest of the division for N).
This will give a number between 0 and N-1 for every key. Connect to this server
and store the key. The same for gets.

This is a basic way of performing key partitioning, consistent hashing is much
better and this is why after Redis 1.0 will be released we'll try to implement
this in every widely used client library starting from Python and PHP (Ruby
already implements this support).

## I'm using some form of key hashing for partitioning, but what about SORT BY?

With [SortCommand SORT] BY you need that all the _weight keys_ are in the same
Redis instance of the list/set you are trying to sort. In order to make this
possible we developed a concept called _key tags_. A key tag is a special
pattern inside a key that, if preset, is the only part of the key hashed in
order to select the server for this key. For example in order to hash the key
"foo" I simply perform the CRC32 checksum of the whole string, but if this key
has a pattern in the form of the characters {...} I only hash this substring.
So for example for the key "foo{bared}" the key hashing code will simply
perform the CRC32 of "bared". This way using key tags you can ensure that
related keys will be stored on the same Redis instance just using the same key
tag for all this keys. Redis-rb already implements key tags.

## What is the maximum number of keys a single Redis instance can hold? and what the max number of elements in a List, Set, Ordered Set?

In theory Redis can handle up to 2^32 keys, and was tested in practice to
handle at least 150 million of keys per instance. We are working in order to
experiment with larger values.

Every list, set, and ordered set, can hold 2^32 elements.

Actually Redis internals are ready to allow up to 2^64 elements but the current
disk dump format don't support this, and there is a lot time to fix this issues
in the future as currently even with 128 GB of RAM it's impossible to reach
2^32 elements.

## What Redis means actually?

Redis means two things:

* It means REmote DIctionary Server
* It is a joke on the word Redistribute (instead to use just a Relational DB
  redistribute your workload among Redis servers)

## Why did you started the Redis project?

In order to scale [LLOOGG][lloogg]. But after I got the basic server
working I liked the idea to share the work with other guys, and Redis was
turned into an open source project.

[lloogg]: http://lloogg.com
