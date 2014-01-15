Replication
===

Redis replication is a very simple to use and configure master-slave
replication that allows slave Redis servers to be exact copies of
master servers. The following are some very important facts about Redis
replication:

* Redis uses asynchronous replication. Starting with Redis 2.8,
however, slaves will periodically acknowledge the amount of data
processed from the replication stream.

* A master can have multiple slaves.

* Slaves are able to accept connections from other slaves. Aside from
connecting a number of slaves to the same master, slaves can also be
connected to other slaves in a graph-like structure.

* Redis replication is non-blocking on the master side. This means that
the master will continue to handle queries when one or more slaves perform
the initial synchronization.

* Replication is also non-blocking on the slave side. While the slave is performing
the initial synchronization, it can handle queries using the old version of
the dataset, assuming you configured Redis to do so in redis.conf.
Otherwise, you can configure Redis slaves to return an error to clients if the
replication stream is down. However, after the initial sync, the old dataset
must be deleted and the new one must be loaded. The slave will block incoming
connections during this brief window.

* Replication can be used both for scalability, in order to have
multiple slaves for read-only queries (for example, heavy `SORT`
operations can be offloaded to slaves), or simply for data redundancy.

* It is possible to use replication to avoid the cost of writing the master
write the full dataset to disk: just configure your master redis.conf to avoid
saving (just comment all the "save" directives), then connect a slave
configured to save from time to time.

How Redis replication works
---

If you set up a slave, upon connection it sends a SYNC command. It doesn't
matter if it's the first time it has connected or if it's a reconnection.

The master then starts background saving, and starts to buffer all new
commands received that will modify the dataset. When the background
saving is complete, the master transfers the database file to the slave,
which saves it on disk, and then loads it into memory. The master will
then send to the slave all buffered commands. This is done as a
stream of commands and is in the same format of the Redis protocol itself.

You can try it yourself via telnet. Connect to the Redis port while the
server is doing some work and issue the `SYNC` command. You'll see a bulk
transfer and then every command received by the master will be re-issued
in the telnet session.

Slaves are able to automatically reconnect when the master <->
slave link goes down for some reason. If the master receives multiple
concurrent slave synchronization requests, it performs a single
background save in order to serve all of them.

When a master and a slave reconnects after the link went down, a full resync
is always performed. However, starting with Redis 2.8, a partial resynchronization
is also possible.

Partial resynchronization
---

Starting with Redis 2.8, master and slave are usually able to continue the
replication process without requiring a full resynchronization after the
replication link went down.

This works by creating an in-memory backlog of the replication stream on the
master side. The master and all the slaves agree on a *replication
offset* and a *master run id*, so when the link goes down, the slave will
reconnect and ask the master to continue the replication. Assuming the
master run id is still the same, and that the offset specified is available
in the replication backlog, replication will resume from the point where it left off.
If either of these conditions are unmet, a full resynchronization is performed
(which is the normal pre-2.8 behavior).

The new partial resynchronization feature uses the `PSYNC` command internally,
while the old implementation uses the `SYNC` command. Note that a Redis 2.8
slave is able to detect if the server it is talking with does not support
`PSYNC`, and will use `SYNC` instead.

Configuration
---

To configure replication is trivial: just add the following line to the slave
configuration file:

    slaveof 192.168.1.1 6379

Of course you need to replace 192.168.1.1 6379 with your master IP address (or
hostname) and port. Alternatively, you can call the `SLAVEOF` command and the
master host will start a sync with the slave.

There are also a few parameters for tuning the replication backlog taken
in memory by the master to perform the partial resynchronization. See the example
`redis.conf` shipped with the Redis distribution for more information.

Read-only slave
---

Since Redis 2.6, slaves support a read-only mode that is enabled by default.
This behavior is controlled by the `slave-read-only` option in the redis.conf file, and can be enabled and disabled at runtime using `CONFIG SET`.

Read-only slaves will reject all write commands, so that it is not possible to write to a slave because of a mistake. This does not mean that the feature is intended to expose a slave instance to the internet or more generally to a network where untrusted clients exist, because administrative commands like `DEBUG` or `CONFIG` are still enabled. However, security of read-only instances can be improved by disabling commands in redis.conf using the `rename-command` directive.

You may wonder why it is possible to revert the read-only setting
and have slave instances that can be target of write operations.
While those writes will be discarded if the slave and the master
resynchronize or if the slave is restarted, there's a legitimate
use case for storing ephemeral data in writable slaves. For
instance, clients may take information about master reachability
to coordinate a failover strategy.

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

You may think at it as a relaxed version of the "C" in the CAP theorem, where consistency is not ensured for a given write, but at least the time window for data loss is restricted to a given number of seconds.

If the conditions are not met, the master will instead reply with an error and the write will not be accepted.

There are two configuration parameters for this feature:

* min-slaves-to-write `<number of slaves>`
* min-slaves-max-lag `<number of seconds>`

For more information, please check the example `redis.conf` file shipped with the
Redis source distribution.
