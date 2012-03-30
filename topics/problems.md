Problems with Redis? This is a good starting point.
===

This page tries to help you about what to do if you have issues with Redis. Part of the Redis project is helping people that are experiencing problems because we don't like to let people alone with their issues.

* If you have **latency problems** with Redis, that in some way appears to be idle for some time, read our [Redis latency trubleshooting guide](/topics/latency).
* Redis stable releases are usually very reliable, however in the rare event you are **experiencing crashes** the developers can help a lot more if you provide debugging informations. Please read our [Debugging Redis guide](/topics/debugging).
* It happened multiple times that users experiencing problems with Redis actually had a server with **broken RAM**. Please test your RAM using **redis-server --test-memory** in case Redis is not stable in your system. Redis built-in memory test is fast and reasonably reliable, but if you can you should reboot your server and use [memtest86](http://memtest86.com).

For every other problem please drop a message to the [Redis Google Group](http://groups.google.com/group/redis-db). We will be glad to help.

List of known critical bugs in previous Redis releases.
===

Note: this list may not be complete as we staretd it March 30, 2012, and did not included much historical data.

* Redis version up to 2.4.9: **memory leak in replication**. A memory leak was triggered by replicating a master contaning a database ID greatear than ID 9.
* Redis version up to 2.4.9: **chained replication bug**. In environments where a slave B is attached to another instance `A`, and the instance `A` is switched between master and slave using the `SLAVEOF` command, it is possilbe that `B` will not be correctly disconnected to force a resync when `A` changes status (and data set content).
* Redis version up to 2.4.7: **redis-check-aof does not work properly in 32 bit instances with AOF files bigger than 2GB**.
* Redis version up to 2.4.7: **Mixing replication and maxmemory produced bad results**. Specifically a master with maxmemory set with attached slaves could result into the master blocking and the dataset on the master to get completely erased. The reason was that key expiring produced more memory usabe because of the replication link DEL synthesizing, triggering the expiring of more keys.
* Redis versions up to 2.4.5: **Connection of multiple slaves at the same time could result into big master memory usage, and slave desync**. (See [issue 141](http://github.com/antirez/redis/issues/141) for more details).

List of known bugs still present in latest 2.4 release.
===

* Redis version up to the current 2.4.x release: **Variadic list push commands and blocking list operations will not play well**. If you use `LPUSH` or `RPUSH` commands against a key that has other clients waiting for elements with blocking operations such as `BLPOP`, both the results of the computation the replication on slaves, and the AOF file commands produced, may not be correct. This bug is fixed in Redis 2.6 but unfortunately a too big refactoring was needed to fix the bug, large enough to make a back port more problematic than the bug itself.

List of known bugs still present in latest 2.6 release.
===

* There are no known important bugs in Redis 2.6.x

List of known Linux related bugs affecting Redis.
===

* Ubuntu 10.04 and 10.10 have serious bugs (especially 10.10) that cause slow downs if not just instance hangs. Please move away from the default kernels shipped with this distributions. [Link to 10.04 bug](https://silverline.librato.com/blog/main/EC2_Users_Should_be_Cautious_When_Booting_Ubuntu_10_04_AMIs). [Link to 10.10 bug](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/666211). Both bugs were reported many times in the context of EC2 instances, but other users confirmed that also native servers are affected (at least by one of the two).
