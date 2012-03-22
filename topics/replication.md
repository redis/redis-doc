Replication
===

Redis replication is a very simple to use and configure master-slave
replication that allows slave Redis servers to be exact copies of
master servers. The following are some very important facts about Redis
replication:

* A master can have multiple slaves.

* Slaves are able to accept other slaves connections. Aside from
connecting a number of slaves to the same master, slaves can also be
connected to other slaves in a graph-like structure.

* Redis replication is non-blocking on the master side, this means that
the master will continue to serve queries when one or more slaves perform
the first synchronization.

* Replication is non blocking on the slave side: while the slave is performing
the first synchronization it can reply to queries using the old version of
the data set, assuming you configured Redis to do so in redis.conf.
Otherwise you can configure Redis slaves to send clients an error if the
link with the master is down. However there is a moment where the old dataset must be deleted and the new one must be loaded by the slave where it will block incoming connections.

* Replications can be used both for scalability, in order to have
multiple slaves for read-only queries (for example, heavy `SORT`
operations can be offloaded to slaves, or simply for data redundancy.

* It is possible to use replication to avoid the saving process on the
master side: just configure your master redis.conf to avoid saving
(just comment all the "save" directives), then connect a slave
configured to save from time to time.

How Redis replication works
---

If you set up a slave, upon connection it sends a SYNC command. And
it doesn't matter if it's the first time it has connected or if it's
a reconnection.

The master then starts background saving, and collects all new
commands received that will modify the dataset. When the background
saving is complete, the master transfers the database file to the slave,
which saves it on disk, and then loads it into memory. The master will
then send to the slave all accumulated commands, and all new commands
received from clients that will modify the dataset. This is done as a
stream of commands and is in the same format of the Redis protocol itself.

You can try it yourself via telnet. Connect to the Redis port while the
server is doing some work and issue the `SYNC` command. You'll see a bulk
transfer and then every command received by the master will be re-issued
in the telnet session.

Slaves are able to automatically reconnect when the master <->
slave link goes down for some reason. If the master receives multiple
concurrent slave synchronization requests, it performs a single
background save in order to serve all of them.

When a master and a slave reconnects after the link went down, a full resync is performed.

Configuration
---

To configure replication is trivial: just add the following line to the slave
configuration file:

    slaveof 192.168.1.1 6379

Of course you need to replace 192.168.1.1 6379 with your master IP address (or
hostname) and port. Alternatively, you can call the `SLAVEOF` command and the
master host will start a sync with the slave.

Read only slave
---

Since Redis 2.6 slaves support a read-only mode that is enabled by default.
This behavior is controlled by the `slave-read-only` option in the redis.conf file, and can be enabled and disabled at runtime using `CONFIG SET`.

Read only slaves will reject all the write commadns, so that it is not possible to write to a slave because of a mistake. This does not mean that the feature is conceived to expose a slave instance to the internet or more generally to a network where untrusted clients exist, because administrative commands like `DEBUG` or `CONFIG` are still enabled. However security of read-only instances can be improved disabling commands in redis.conf using the `rename-command` directive.

You may wonder why it is possible to revert the default and have slave instances that can be target of write operations. The reason is that while this writes will be discarded if the slave and the master will resynchronize, or if the slave is restarted, often there is ephemeral data that is unimportant that can be stored into slaves. For instance clients may take information about reachability of master in the slave instance to coordinate a fail over strategy.

Setting a slave to authenticate to a master
---

If your master has a password via `requirepass`, it's trivial to configure the
slave to use that password in all sync operations.

To do it on a running instance, use `redis-cli` and type:

    config set masterauth <password>

To set it permanently, add this to your config file:

    masterauth <password>
