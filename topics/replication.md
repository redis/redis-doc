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
the first synchronization. Instead, replication is blocking on the slave
side: while the slave is performing the first synchronization it can't
reply to queries.

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

Configuration
---

To configure replication is trivial: just add the following line to the slave configuration file:

    slaveof 192.168.1.1 6379

Of course you need to replace 192.168.1.1 6379 with your master ip address (or hostname) and port.