Replication
===

Redis replication is a very simple to use and configure master-slave
replication that allows slave Redis servers to be exact copies of
master servers. The following are some very important facts about Redis
replication:

* A master can have multiple slaves.

* Slaves are able to accept other slaves connections, so instead
to connect a number of slaves against the same master it is also
possible to connect some of the slaves to other slaves in a graph-alike
structure.

* Redis replication is non-blocking on the master side, this means that
the master will continue to serve queries while one or more slaves are
performing the first synchronization. Instead replication is blocking on
the slave side: while the slave is performing the first synchronization
it can't reply to queries.

* Replications can be used both for scalability, in order to have
multiple slaves for read-only queries (for example heavy `SORT`
operations can be launched against slaves), or simply for data
redundancy.

* It is possible to use replication to avoid the saving process on the
master side: just configure your master redis.conf in order to avoid
saving at all (just comment al the "save" directives), then connect a
slave configured to save from time to time.

How Redis replication works
---

In order to start the replication, or after the connection closes in
order resynchronize with the master, the slave connects to the master
and issues the `SYNC` command.

The master starts a background saving, and at the same time starts to
collect all the new commands received that had the effect to modify the
dataset. When the background saving completed the master starts the
transfer of the database file to the slave, that saves it on disk, and
then load it in memory. At this point the master starts to send all the
accumulated commands, and all the new commands received from clients
that had the effect of a dataset modification, to the slave, as a stream
of commands, in the same format of the Redis protocol itself.

You can try it yourself via telnet. Connect to the Redis port while the
server is doing some work and issue the `SYNC` command. You'll see a bulk
transfer and then every command received by the master will be re-issued
in the telnet session.

Slaves are able to automatically reconnect when the master <->
slave link goes down for some reason. If the master receives multiple
concurrent slave synchronization requests it performs a single
background saving in order to serve all them.

Configuration
---

To configure replication is trivial: just add the following line to the slave configuration file:

    slaveof 192.168.1.1 6379

Of course you need to replace 192.168.1.1 6379 with your master ip address (or hostname) and port.
