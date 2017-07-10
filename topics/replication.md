Replication
===

At the base of Redis replication there is a very simple to use and configure
master-slave replication that allows slave Redis servers to be exact copies of
master servers. The slave will automatically reconnect to the master every
time the link breaks, and will attempt to be an exact copy of it regardless
of what happens to the master.

This system works using three main mechanisms:

1. When a master and a slave instance are well-connected, the master keeps the slave updated by sending a stream of commands in order to replicate the effects on the dataset happening in the master dataset: client writes, keys expiring or evicted, and so forth.
2. When the link between the master and the slave breaks, for network issues or because a timeout is sensed in the master or the slave, the slave reconnects and attempts to proceed with a partial resynchronization: it means that it will try to just obtain the part of the stream of commands it missed during the disconnection.
3. When a partial resynchronization is not possible, the slave will ask for a full resynchronization. This will involve a more complex process in which the master needs to create a snapshot of all its data, send it to the slave, and then continue sending the stream of commands as the dataset changes.

Redis uses by default asynchronous replication, which being high latency and
high performance, is the natural replication mode for the vast majority of Redis
use cases. However Redis slaves asynchronously acknowledge the amount of data
the received periodically with the master.

Synchronous replication of certain data can be requested by the clients using
the `WAIT` command. However `WAIT` is only able to ensure that there are the
specified number of acknowledged copies in the other Redis instances: acknowledged
writes can still be lost during a failover for different reasons during a
failover or depending on the exact configuration of the Redis persistence.
You could check the Sentinel or Redis Cluster documentation for more information
about high availability and failover. The rest of this document mainly describe the basic characteristics of Redis basic replication.

The following are some very important facts about Redis replication:

* Redis uses asynchronous replication, with asynchronous slave-to-master acknowledges of the amount of data processed.

* A master can have multiple slaves.

* Slaves are able to accept connections from other slaves. Aside from
connecting a number of slaves to the same master, slaves can also be
connected to other slaves in a cascading-like structure. Since Redis 4.0, all the sub-slaves will receive exactly the same replication stream from the master.

* Redis replication is non-blocking on the master side. This means that
the master will continue to handle queries when one or more slaves perform
the initial synchronization or a partial resynchronization.

* Replication is also largely non-blocking on the slave side. While the slave is performing the initial synchronization, it can handle queries using the old version of the dataset, assuming you configured Redis to do so in redis.conf.
Otherwise, you can configure Redis slaves to return an error to clients if the
replication stream is down. However, after the initial sync, the old dataset
must be deleted and the new one must be loaded. The slave will block incoming
connections during this brief window (that can be as long as many seconds for very large datasets). Since Redis 4.0 it is possible to configure Redis so that the deletion of the old data set happens in a different thread, however loading the new initial dataset will still happen in the main thread and block the slave.

* Replication can be used both for scalability, in order to have
multiple slaves for read-only queries (for example, slow O(N)
operations can be offloaded to slaves), or simply for data safety.

* It is possible to use replication to avoid the cost of having the master write the full dataset to disk: a typical technique involves configuring your master `redis.conf` to avoid persisting to disk at all, then connect a slave configured to save from time to time, or with AOF enabled. However this setup must be handled with care, since a restarting master will start with an empty dataset: if the slave tries to synchronized with it, the slave will be emptied as well.

Safety of replication when master has persistence turned off
---

In setups where Redis replication is used, it is strongly advised to have
persistence turned on in the master and in the slaves. When this is not possible,
for example because of latency concerns due to very slow disks, instances should
be configured to **avoid restarting automatically** after a reboot.

To better understand why masters with persistence turned off configured to
auto restart are dangerous, check the following failure mode where data
is wiped from the master and all its slaves:

1. We have a setup with node A acting as master, with persistence turned down, and nodes B and C replicating from node A.
2. Node A crashes, however it has some auto-restart system, that restarts the process. However since persistence is turned off, the node restarts with an empty data set.
3. Nodes B and C will replicate from node A, which is empty, so they'll effectively destroy their copy of the data.

When Redis Sentinel is used for high availability, also turning off persistence
on the master, together with auto restart of the process, is dangerous. For example the master can restart fast enough for Sentinel to don't detect a failure, so that the failure mode described above happens.

Every time data safety is important, and replication is used with master configured without persistence, auto restart of instances should be disabled.

How Redis replication works
---

Every Redis master has a replication ID: it is a large pseudo random string
that marks a given story of the dataset. Each master also takes an offset that
increments for every byte of replication stream that it is produced to be
sent to slaves, in order to update the state of the slaves with the new changes
modifying the dataset. The replication offset is incremented even if no slave
is actually connected, so basically every given pair of:

    Replication ID, offset

Identifies an exact version of the dataset of a master.

When slaves connects to master, they use the `PSYNC` command in order to send
their old master replication ID and the offsets they processed so far. This way
the master can send just the incremental part needed. However if there is not
enough *backlog* in the master buffers, or if the slave is referring to an
history (replication ID) which is no longer known, than a full resynchronization
happens: in this case the slave will get a full copy of the dataset, from scratch.

This is how a full synchronization works in more details:

The master starts a background saving process in order to produce an RDB file. At the same time it starts to buffer all new write commands received from the clients. When the background saving is complete, the master transfers the database file to the slave, which saves it on disk, and then loads it into memory. The master will then send all buffered commands to the slave. This is done as a stream of commands and is in the same format of the Redis protocol itself.

You can try it yourself via telnet. Connect to the Redis port while the
server is doing some work and issue the `SYNC` command. You'll see a bulk
transfer and then every command received by the master will be re-issued
in the telnet session. Actually `SYNC` is an old protocol no longer used by
newer Redis instances, but is still there for backward compatibility: it does
not allow partial resynchronizations, so now `PSYNC` is used instead.

As already said, slaves are able to automatically reconnect when the master-slave link goes down for some reason. If the master receives multiple concurrent slave synchronization requests, it performs a single background save in order to serve all of them.

Diskless replication
---

Normally a full resynchronization requires to create an RDB file on disk,
then reload the same RDB from disk in order to feed the slaves with the data.

With slow disks this can be a very stressing operation for the master.
Redis version 2.8.18 is the first version to have support for diskless
replication. In this setup the child process directly sends the
RDB over the wire to slaves, without using the disk as intermediate storage.

Configuration
---

To configure basic Redis replication is trivial: just add the following line to the slave configuration file:

    slaveof 192.168.1.1 6379

Of course you need to replace 192.168.1.1 6379 with your master IP address (or
hostname) and port. Alternatively, you can call the `SLAVEOF` command and the
master host will start a sync with the slave.

There are also a few parameters for tuning the replication backlog taken
in memory by the master to perform the partial resynchronization. See the example
`redis.conf` shipped with the Redis distribution for more information.

Diskless replication can be enabled using the `repl-diskless-sync` configuration
parameter. The delay to start the transfer in order to wait more slaves to
arrive after the first one, is controlled by the `repl-diskless-sync-delay`
parameter. Please refer to the example `redis.conf` file in the Redis distribution
for more details.

Read-only slave
---

Since Redis 2.6, slaves support a read-only mode that is enabled by default.
This behavior is controlled by the `slave-read-only` option in the redis.conf file, and can be enabled and disabled at runtime using `CONFIG SET`.

Read-only slaves will reject all write commands, so that it is not possible to write to a slave because of a mistake. This does not mean that the feature is intended to expose a slave instance to the internet or more generally to a network where untrusted clients exist, because administrative commands like `DEBUG` or `CONFIG` are still enabled. However, security of read-only instances can be improved by disabling commands in redis.conf using the `rename-command` directive.

You may wonder why it is possible to revert the read-only setting
and have slave instances that can be targeted by write operations.
While those writes will be discarded if the slave and the master
resynchronize or if the slave is restarted, there are a few legitimate
use case for storing ephemeral data in writable slaves.

For example computing slow Set or Sorted set operations and storing them into local keys is an use case for writable slaves that was observed multiple times.

However note that **writable slaves before version 4.0 were uncapable of expiring keys with a time to live set**. This means that if you use `EXPIRE` or other commands that set a maximum TTL for a key, the key will leak, and while you may no longer see it while accessing it with read commands, you will see it in the count of keys and it will still use memory. So in general mixing writable slaves (previous version 4.0) and keys with TTL is going to create issues.

Redis 4.0 RC3 and greater versions totally solve this problem and now writable
slaves are able to evict keys with TTL as masters do, with the exceptions
of keys written in DB numbers greater than 63 (but by default Redis instances
only have 16 databases).

Also note that since Redis 4.0 slave writes are only local, and are not propagated to sub-slaves attached to the instance. Sub slaves instead will always receive the replication stream identical to the one sent by the top-level master to the intermediate slaves. So for example in the following setup:

    A ---> B ---> C

Even if `B` is writable, C will not see `B` writes and will instead have identical dataset as the master instance `A`.

Setting a slave to authenticate to a master
---

If your master has a password via `requirepass`, it's trivial to configure the
slave to use that password in all sync operations.

To do it on a running instance, use `redis-cli` and type:

    config set masterauth <password>

To set it permanently, add this to your config file:

    masterauth <password>

Allow writes only with N attached replicas
---

Starting with Redis 2.8, it is possible to configure a Redis master to
accept write queries only if at least N slaves are currently connected to the
master.

However, because Redis uses asynchronous replication it is not possible to ensure
the slave actually received a given write, so there is always a window for data
loss.

This is how the feature works:

* Redis slaves ping the master every second, acknowledging the amount of replication stream processed.
* Redis masters will remember the last time it received a ping from every slave.
* The user can configure a minimum number of slaves that have a lag not greater than a maximum number of seconds.

If there are at least N slaves, with a lag less than M seconds, then the write will be accepted.

You may think of it as a best effort data safety mechanism, where consistency is not ensured for a given write, but at least the time window for data loss is restricted to a given number of seconds. In general bound data loss is better than unbound one.

If the conditions are not met, the master will instead reply with an error and the write will not be accepted.

There are two configuration parameters for this feature:

* min-slaves-to-write `<number of slaves>`
* min-slaves-max-lag `<number of seconds>`

For more information, please check the example `redis.conf` file shipped with the
Redis source distribution.

How Redis replication deals with expires on keys
---

Redis expires allow keys to have a limited time to live. Such a feature depends
on the ability of an instance to count the time, however Redis slaves correctly
replicate keys with expires, even when such keys are altered using Lua
scripts.

To implement such a feature Redis cannot rely on the ability of the master and
slave to have synchronized clocks, since this is a problem that cannot be solved
and would result into race conditions and diverging data sets, so Redis
uses three main techniques in order to make the replication of expired keys
able to work:

1. Slaves don't expire keys, instead they wait for masters to expire the keys. When a master expires a key (or evict it because of LRU), it synthesizes a `DEL` command which is transmitted to all the slaves.
2. However because of master-driven expire, sometimes slaves may still have in memory keys that are already logically expired, since the master was not able to provide the `DEL` command in time. In order to deal with that the slave uses its logical clock in order to report that a key does not exist **only for read operations** that don't violate the consistency of the data set (as new commands from the master will arrive). In this way slaves avoid to report logically expired keys are still existing. In practical terms, an HTML fragments cache that uses slaves to scale will avoid returning items that are already older than the desired time to live.
3. During Lua scripts executions no keys expires are performed. As a Lua script runs, conceptually the time in the master is frozen, so that a given key will either exist or not for all the time the script runs. This prevents keys to expire in the middle of a script, and is needed in order to send the same script to the slave in a way that is guaranteed to have the same effects in the data set.

As it is expected, once a slave is turned into a master because of a fail over, it start to expire keys in an independent way without requiring help from its old master.

Configuring replication in Docker and NAT
---

When Docker, or other types of containers using port forwarding, or Network Address Translation is used, Redis replication needs some extra care, especially when using Redis Sentinel or other systems where the master `INFO` or `ROLE` commands output are scanned in order to discover slaves addresses.

The problem is that the `ROLE` command, and the replication section of
the `INFO` output, when issued into a master instance, will show slaves
as having the IP address they use to connect to the master, which, in
environments using NAT may be different compared to the logical address of the
slave instance (the one that clients should use to connect to slaves).

Similarly the slaves will be listed with the listening port configured
into `redis.conf`, that may be different than the forwarded port in case
the port is remapped.

In order to fix both issues, it is possible, since Redis 3.2.2, to force
a slave to announce an arbitrary pair of IP and port to the master.
The two configurations directives to use are:

    slave-announce-ip 5.5.5.5
    slave-announce-port 1234

And are documented in the example `redis.conf` of recent Redis distributions.

The INFO and ROLE command
---

There are two Redis commands that provide a lot of information on the current
replication parameters of master and slave instances. One is `INFO`. If the
command is called with the `replication` argument as `INFO replication` only
information relevant to the replication are displayed. Another more
computer-friendly command is `ROLE`, that provides the replication status of
masters and slaves together with their replication offsets, list of connected
slaves and so forth.

Partial resynchronizations after restarts and failovers
---

Since Redis 4.0, when an instance instance is promoted to master after a failover,
it will be still able to perform a partial resynchronization with the slaves
of the old master. To do so, the slave remembers the old replication ID and
offset of its former master, so can provide part of the backlog to the connecting
slaves even if they ask for the old replication ID.

However the new replication ID of the promoted slave will be different, since it
constitutes a different history of the data set. For example, the master can
return available and can continue accepting writes for some time, so using the
same replication ID in the promoted slave would violate the rule that a
of replication ID and offset pair identifies only a single data set.

Moreover slaves when powered off gently and restarted, are able to store in the
`RDB` file the information needed in order to resynchronize with their master.
This is useful in case of upgrades. When this is needed, it is better to use
the `SHUTDOWN` command in order to perform a `save & quit` operation on the slave.
