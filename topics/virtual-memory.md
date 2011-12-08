**IMPORTANT NOTE:** Redis VM is now deprecated. Redis 2.4 will be the
latest Redis version featuring Virtual Memory (but it also warns you
that Virtual Memory usage is discouraged). We found that using VM has
several disadvantages and problems. In the future of Redis we want to
simply provide the best in-memory database (but persistent on disk as
usually) ever, without considering, at least for now, the support for
databases bigger than RAM. Our future efforts are focused on providing
scripting, cluster, and better persistence.

Virtual Memory
===

Redis Virtual Memory is a feature that will appear for the first time in a
stable Redis distribution in Redis 2.0. However Virtual Memory (called VM
starting from now) is already available and stable enough to be tested in the
unstable branch of Redis available [on Git][redissrc].

[redissrc]: http://github.com/antirez/redis

## Virtual Memory explained in simple words

Redis follows a Key-Value model. You have keys associated with the values.
Usually Redis stores both Keys and the associated Values in the memory.
Sometimes this is not the best option, and while Keys *must* be stored in
memory by design (and in order to ensure fast lookups), Values can be swapped
out to the disk when they are rarely used.

In practical terms this means that if you have a dataset of 100,000 keys in the
memory, but only 10% of the keys are often used, Redis with the Virtual Memory
being enabled will try to transfer the values associated with the rarely used
keys to the disk.

When these values are requested, for example, as a result of a command issued
by a client, the values are loaded back from the swap file to the main memory.

## When using Virtual Memory is a good idea

Before using the VM you should ask yourself if you really need it. Redis is a
disk backed, in memory database. The right way to use Redis is almost always to
have enough RAM to fit all the data in the memory. Still there are scenarios
where this is not possible:

* Data access is very biased. Only a small percentage of the keys (for instance
  related to the active users in your web site) gets the vast majority of
  accesses.  At the same time there is way too much data per key to store
  everything in the memory.
* Simply put there is not enough memory available to hold all the data in the
  memory, regardless of the data access pattern, and the values are too large.
  In this configuration Redis can be used as an on-disk DB where keys are
  stored in the memory, so the key lookups are fast, but access to the actual
  values requires hitting the (slower) disk.

An important concept to keep in mind is that Redis *has to store the keys in the
memory*, so if your memory problems are related to the fact that you have a lot
of keys with very small values, the VM would not help you to resolve the issue.

However if a great deal of the memory is used to store pretty large values (for
example large strings, lists, sets or hashes with many elements), then the VM can
be of big help.

Sometimes you can turn your "many keys with small values" problem into "a few
keys but with very large values" one by just using *hashes* in order to group
related data into fields of a single key. For example, instead of having a key
for every attribute of your object you may have a single key per object where
*hash* fields represent the different attributes.

## VM Configuration

Configuring the VM is not that hard but requires some care to set the best
parameters according to the requirements.

The VM is enabled and configured by editing `redis.conf`. The first step is to
switch it on with help of:

    vm-enabled yes

Many other configuration options provide possibility to change the behaviour of
the VM. The rule of the thumb is that you don't want to run with the default
configuration, as every problem and dataset requires some fine-tuning to get
the maximum advantage.

## The vm-max-memory setting

The `vm-max-memory` setting specifies how much memory Redis is free to use
before starting swapping values to the disk.

Basically, if this memory limit is not reached, no object are swapped, and
Redis works with all the objects in the memory as usual. However, once this
limit is hit, enough objects are swapped out to return the memory usage just
under the limit.

The swapped objects are primarily the ones with the highest "age" (that is, the
number of seconds since they have been used for the last time), but the
"swappability" of an object is also proportional to the logarithm of it's size
in the memory. So although older objects are preferred, bigger objects are
swapped out first when they are about of the same age.

*WARNING:* Because keys can't be swapped out, Redis will not be able to honour
the *vm-max-memory* setting if the keys alone are using more space than the
limit.

The best value for this setting is *enough RAM to hold the "working set" of the
data*. In practical terms, just give Redis as much memory as you can, and
the swapping will work better.

## Configuring the swap file

In order to transfer data from the memory to the disk, Redis uses a swap file.
The swap file has nothing to do with the durability of the data, and can be
removed when a Redis instance is terminated. However, the swap file should not
be moved, deleted, or altered in any other way while Redis is running.

Because the Redis swap file is used mostly in a random access fashion, putting
the swap file on a Solid State Disk brings better performance.

The swap file is divided into "pages". A swapped value can be occupy one or
multiple pages, but a single page can't hold more than one value.

There is no direct way to tell Redis how much bytes of the swap file it should
be using. Instead two different values are configured, when multiplied together
those values produce the total number of bytes to use. These two values are the
number of the pages inside a swap file, and a page size. It is possible to
configure these two parameters in `redis.conf`.

* The *vm-pages* configuration directive is used to set the total number of the
  pages in the swap file.
* the *vm-page-size* configuration directive is used to set a page size in
  bytes.

For instance, if a page size is set to 32 bytes, and the total number of pages
is set to 10000000 (10 million), the swap file can hold a total of 320 MB
(megabytes) of the data.

Because a single page can't be used to hold more than one value (but a value can
be stored in multiple pages), care must be taken in setting these parameters.
Usually the best idea is to set the page size so that the majority of the
values could be stored in a swap using a few pages.

## Threaded VM vs Blocking VM

Another very important configuration parameter is *vm-max-threads*:

    # The default vm-max-threads configuration
    vm-max-threads 4

It holds the maximum possible number of threads used to perform I/O from/to the
swap file. A good choice is to match the number with the number of CPU cores in
your system.

However the special value of "0" enables the blocking VM mode. When VM is
configured to run in blocking mode it performs the I/O in a synchronous
blocking way. This is what you can expect from the blocking VM:

* Clients accessing swapped out keys will block other clients while reading
  from the disk, so the latency experienced by clients can be larger, especially
  if the disk is slow or busy and/or if there are big values swapped to the disk.
* The blocking VM performance is better *overall*, as no time is lost
  on synchronization, spawning the threads, and resuming the blocked clients
  waiting for values. So if you are willing to accept a higher latency from
  time to time, blocking VM can be a good pick. Especially if swapping happens
  rarely and most of your frequently accessed data happens to fit in the memory.

Instead, if you have a lot of swap in and swap out operations and you have many
cores that you want to exploit, or in general when you don't want the clients
dealing with the swapped values to block other clients for several milliseconds
(or more if the swapped value is very big), then it's better to use threaded VM.

It it warmly encouraged to experiment with your dataset and the configuration
options to get the best results.

# Random things to know

## A good place for the swap file

In many configurations the swap file can be fairly large, amounting to 40GB or
more. Not all kinds of file systems are able to deal with large files in a good
way, especially the Mac OS X file system which tends to be really lame about it.

The recommendation is to use Linux ext3 file system, or any other file system
with a good support for *sparse files*.

### What are the sparse files?

Sparse files are the files whose content happens to have a lot of empty areas.
Advanced file systems like ext2, ext3, ext4, RaiserFS, Raiser4, and many others
can encode these files in a space efficient way and allocate more space for the
file when this is really needed, that is, when more actual blocks of the file
should be used.

The swap file is obviously pretty sparse, especially if a server is running
for not that much time or if the swap file is much bigger compared to the
amount of data swapped out. A file system not supporting sparse files can at
some point block the Redis process while creating a very big file at once.

For a list of file systems supporting spare files, [check out this Wikipedia
article comparing different file systems][wikifs].

[wikifs]: http://en.wikipedia.org/wiki/Comparison_of_file_systems

## Monitoring the VM

Once you have a Redis system with the VM enabled up and running, you may be
very interested to know how it is working: how many objects are swapped in
total, the number of objects swapped and loaded every second, and so forth.

There is a utility that is very handy in checking how the VM is working, which
is a part of the [Redis Tools](http://github.com/antirez/redis-tools). This
tool is called redis-stat:

    $ ./redis-stat vmstat
    --------------- objects --------------- ------ pages ------ ----- memory -----
    load-in  swap-out  swapped   delta      used     delta      used     delta
    138837   1078936   800402    +800402    807620   +807620    209.50M  +209.50M
    4277     38011     829802    +29400     837441   +29821     206.47M  -3.03M
    3347     39508     862619    +32817     870340   +32899     202.96M  -3.51M
    4445     36943     890646    +28027     897925   +27585     199.92M  -3.04M
    10391    16902     886783    -3863      894104   -3821      200.22M  +309.56K
    8888     19507     888371    +1588      895678   +1574      200.05M  -171.81K
    8377     20082     891664    +3293      899850   +4172      200.10M  +53.55K
    9671     20210     892586    +922       899917   +67        199.82M  -285.30K
    10861    16723     887638    -4948      895003   -4914      200.13M  +312.35K
    9541     21945     890618    +2980      898004   +3001      199.94M  -197.11K
    9689     17257     888345    -2273      896405   -1599      200.27M  +337.77K
    10087    18784     886771    -1574      894577   -1828      200.36M  +91.60K
    9330     19350     887411    +640       894817   +240       200.17M  -189.72K

The above output is from a redis-server with the VM enabled, storing around 1
million of keys inside, and being hit by a lot of simulated load using the
redis-load utility.

As you can see from the output above a lot of load-in and swap-out operations
are happening every second. Note that the first line reports the actual values
since the server has been started, while the next lines are differences
compared to the previous reading.

If you assigned enough memory to hold your working set of the data, probably
you should see much less dramatic swapping happening, so redis-stat can be a
really valuable tool in order to understand if you need to shop for RAM ;)

## Redis with VM enabled: better .rdb files or Append Only File?

When the VM is enabled, operations concerning saving and loading the database
become *much slower*. With the VM enabled, a DB that usually loads in 2 seconds
can take up to 13 seconds to load if the server is configured to use the
smallest memory possible (that is, vm-max-memory set to 0).

So you may probably want to switch to a configuration with usage of the Append
Only File for persistence, so that you could perform the `BGREWRITEAOF` call
from time to time.

It is important to note that while a `BGSAVE` or `BGREWRITEAOF` is in progress
Redis does *not* swap new values to the disk. The VM will be read-only while there
is another child accessing it. So if you have a lot of writes when there is a
child working, the memory usage may grow.

## Using as little memory as possible

An interesting setup to turn Redis into is an on-disk DB with just the keys in
the memory and with with `vm-max-memory` option set to 0. If you don't mind
some higher latency and poorer performance but want to use the least amount of
the memory possible for very big values, this is a good setup.

In this setup you should first switch the VM into blocking mode
(`vm-max-threads 0`) as with this configuration and high traffic the number of
swap in and swap out operations will be huge, and threading will consume a lot
of resources compared to a simple blocking implementation.

## VM Stability

The VM is still an experimental code, but over the last few weeks it was tested
in many ways in the development environments, and even in some production
environments. No bugs were found during this testing period. Still some obscure
bugs may happen in the environments out of our control with the setups that we
can not reproduce for some reason.

In this stage you are encouraged to try the VM in your development environment,
or even in the production if your DB is not mission critical, but, for
instance, holds a big persistent cache of the data that may go away without too
much problems.

Please report any problem you notice to the Redis Google Group or by joining
IRC channel #redis on irc.freenode.net.
