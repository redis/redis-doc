Redis Administration
===

This page contains topics related to administration of Redis.
Every topic is self contained in form of a FAQ. New topics will be created in the future.

Upgrading or restarting Redis instance without downtime
-------------------------------------------------------

Redis is designed to be a very long running process in your server.
For instance many configurations options can be modified without any kind of restart using the [CONFIG command](/commands/config).

Starting from Redis 2.2 it is even possible to switch from AOF to RDB snapshots persistence or the other way around without restarting Redis. Check the output of the 'CONFIG GET *' command for more information.

However from time to time a restart is mandatory, for instance in order to upgrade the Redis process to a newer version, or when you need to modify some configuration parameter that is currently not supported by the CONFIG command.

The following steps provide a very commonly used way in order to avoid any downtime.

* Setup your new Redis instance as a slave for your current Redis instance. In order to do so you need a different server, or a server that has enough RAM to keep two instances of Redis running at the same time.
* If you use a single server, make sure that the slave is started in a different port then the master instance, otherwise the slave will not be able to start at all.
* Wait for the replication initial synchronization to complete (check the slave log file).
* Make sure using INFO that actually there are the same number of keys in the master and in the slave. Check with redis-cli that the salve is working as you wish.
* Configure all your clients in order to use the new instance (that is, the slave).
* Once you are sure that the master is no longer receiving any query (you can check this with the [MONITOR command](/commands/monitor)), elect the slave as master using the *SLAVEOF NO ONE* command, and shut down your master.
