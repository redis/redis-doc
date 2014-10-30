Redis Administration
===

This page contains topics related to the administration of Redis instances.
Every topic is self contained in form of a FAQ. New topics will be created in the future.

Redis setup hints
-----------------

+ We suggest deploying Redis using the **Linux operating system**. Redis is also tested heavily on OS X, and tested from time to time on FreeBSD and OpenBSD systems. However Linux is where we do all the major stress testing, and where most production deployments are working.
+ Make sure to set the Linux kernel **overcommit memory setting to 1**. Add `vm.overcommit_memory = 1` to `/etc/sysctl.conf` and then reboot or run the command `sysctl vm.overcommit_memory=1` for this to take effect immediately.
+ Make sure to **setup some swap** in your system (we suggest as much as swap as memory). If Linux does not have swap and your Redis instance accidentally consumes too much memory, either Redis will crash for out of memory or the Linux kernel OOM killer will kill the Redis process.
+ If you are using Redis in a very write-heavy application, while saving an RDB file on disk or rewriting the AOF log **Redis may use up to 2 times the memory normally used**. The additional memory used is proportional to the number of memory pages modified by writes during the saving process, so it is often proportional to the number of keys (or aggregate types items) touched during this time. Make sure to size your memory accordingly.
+ Even if you have persistence disabled, Redis will need to perform RDB saves if you use replication.
+ The use of Redis persistence with **EC2 EBS volumes is discouraged** since EBS performance is usually poor. Use ephemeral storage to persist and then move your persistence files to EBS when possible.
+ If you are deploying using a virtual machine that uses the **Xen hypervisor you may experience slow fork() times**. This may block Redis from a few milliseconds up to a few seconds depending on the dataset size. Check the [latency page](/topics/latency) for more information. This problem is not common to other hypervisors.
+ Use `daemonize no` when run under daemontools.

Upgrading or restarting a Redis instance without downtime
-------------------------------------------------------

Redis is designed to be a very long running process in your server.
For instance many configuration options can be modified without any kind of restart using the [CONFIG SET command](/commands/config-set).

Starting from Redis 2.2 it is even possible to switch from AOF to RDB snapshots persistence or the other way around without restarting Redis. Check the output of the 'CONFIG GET *' command for more information.

However from time to time a restart is mandatory, for instance in order to upgrade the Redis process to a newer version, or when you need to modify some configuration parameter that is currently not supported by the CONFIG command.

The following steps provide a very commonly used way in order to avoid any downtime.

* Setup your new Redis instance as a slave for your current Redis instance. In order to do so you need a different server, or a server that has enough RAM to keep two instances of Redis running at the same time.
* If you use a single server, make sure that the slave is started in a different port than the master instance, otherwise the slave will not be able to start at all.
* Wait for the replication initial synchronization to complete (check the slave log file).
* Make sure using INFO that there are the same number of keys in the master and in the slave. Check with redis-cli that the slave is working as you wish and is replying to your commands.
* Allow writes to the slave using **CONFIG SET slave-read-only no**
* Configure all your clients in order to use the new instance (that is, the slave).
* Once you are sure that the master is no longer receiving any query (you can check this with the [MONITOR command](/commands/monitor)), elect the slave to master using the **SLAVEOF NO ONE** command, and shut down your master.
