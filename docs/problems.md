Problems with Redis? This is a good starting point.
===

This page tries to help you with what to do if you have issues with Redis. Part of the Redis project is helping people that are experiencing problems because we don't like to leave people alone with their issues.

* If you have **latency problems** with Redis, that in some way appears to be idle for some time, read our [Redis latency troubleshooting guide](/topics/latency).
* Redis stable releases are usually very reliable, however in the rare event you are **experiencing crashes** the developers can help a lot more if you provide debugging information. Please read our [Debugging Redis guide](/topics/debugging).
* We have a long history of users experiencing crashes with Redis that actually turned out to be servers with **broken RAM**. Please test your RAM using **redis-server --test-memory** in case Redis is not stable in your system. Redis built-in memory test is fast and reasonably reliable, but if you can you should reboot your server and use [memtest86](http://memtest86.com).

For every other problem please drop a message to the [Redis Google Group](http://groups.google.com/group/redis-db). We will be glad to help.

List of known critical bugs in Redis 3.0.x, 2.8.x and 2.6.x
===

To find a list of critical bugs please refer to the changelogs:

* [Redis 3.0 Changelog](https://raw.githubusercontent.com/redis/redis/3.0/00-RELEASENOTES).
* [Redis 2.8 Changelog](https://raw.githubusercontent.com/redis/redis/2.8/00-RELEASENOTES).
* [Redis 2.6 Changelog](https://raw.githubusercontent.com/redis/redis/2.6/00-RELEASENOTES).

Check the *upgrade urgency* level in each patch release to more easily spot
releases that included important fixes.

List of known Linux related bugs affecting Redis.
===

* Ubuntu 10.04 and 10.10 have serious bugs (especially 10.10) that cause slow downs if not just instance hangs. Please move away from the default kernels shipped with this distributions. [Link to 10.04 bug](https://blog.librato.com/posts/2011/5/16/ec2-users-should-be-cautious-when-booting-ubuntu-1004-amis). [Link to 10.10 bug](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/666211). Both bugs were reported many times in the context of EC2 instances, but other users confirmed that also native servers are affected (at least by one of the two).
* Certain versions of the Xen hypervisor are known to have very bad fork() performances. See [the latency page](/topics/latency) for more information.
