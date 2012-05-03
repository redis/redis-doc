Redis Sentinel design draft
===

Redis Sentinel is the name of the Redis high availability solution that's
currently under development. It has nothing to do with Redis Cluster and
is intended to be used by people that don't need Redis Cluster, but simply
a way to perform automatic fail over when a master instance is not functioning
correctly.

The plan is to provide an usable beta implementaiton of Redis Sentinel in a
short time, preferrably in mid June 2012.

In short this is what Redis Sentinel will be able to do:

1) Monitor master instances to see if they are available.
2) Promote a slave to master when the master fails.
3) Modify clients configurations when a slave is elected.
4) Inform the system administrator about incidents using notifications.

The following document explains what is the design of Redis Sentinel in order
to accomplish this goals.

Redis Sentinel idea
===

The idea of Redis Sentinel is to have multiple "monitoring devices" in
different places of your network, monitoring the Redis master instance.

However this independent devices can't act without agreement with other
sentinels.

Once a Redis master instance is detected as failing, for the fail over process
to start the sentinel must verify that there is a given level of agreement.

The amount of sentinels, their location in the network, and the
"minimal agreement" configured, select the desired behavior among many
possibilities.

Redis Sentinel does not use any proxy: client reconfiguration are performed
running user-provided executables (for instance a shell script or a
Python program) in a user setup specific way.

In what form it will be shipped
===

Redis Sentinel will just be a special mode of the redis-server executable.

If the redis-server is called with "redis-sentinel" as argv[0] (for instance
using a symbolic link or copying the file), or if --sentinel option is passed,
the Redis instance starts in sentinel mode and will only understand sentinel
related commands. All the other commands will be refused.

The whole implementation of sentinel will live in a separated file sentinel.c
with minimal impact on the rest of the code base. However this solution allows
to use all the facilities already implemented inside Redis without any need
to reimplement them or to maintain a separated code base for Redis Sentinel.

Sentinels networking
===

All the sentinels take a connection with the monitored master.

Sentinels use the Redis protocol to talk with each other when needed.

Redis Sentinels export a single SENTINEL command. Subcommands of the SENTINEL
command are used in order to perform different actions.

For instance to check what a sentinel thinks about the state of the master
it is possible to send the "SENTINEL STATUS" command using redis-cli.

There is no gossip going on between sentinels. A sentinel instance will query
other instances only when an agreement is needed about the state of the
master or slaves.

The list of networking tasks performed by every sentinel is the following:

1) A Sentinel PUBLISH its presence using the master Pub/Sub every minute.
2) A Sentinel accepts commands using a TCP port.
3) A Sentinel constantly monitors master and slaves sending PING commands.
4) A Sentinel sends INFO commands to the master every minute in order to take a fresh list of connected slaves.
5) A Sentinel monitors the snetinels Pub/SUb channel in order to discover newly connected setninels.

Sentinels discovering
===

While sentinels don't use some kind of bus interconnecting every Redis Sentinel
instance to each other, they still need to know the IP address and port of
each other sentinel instance, because this is useful to run the agreement
protocol needed to perform the slave election.

To make the configuration of sentinels as simple as possible every sentinel
broadcasts its presence using the Redis master Pub/Sub functionality.

Every sentinel is subscribed to the same channel, and broadcast information
about its existence to the same channel, including the "Run ID" of the Sentinel,
and the IP address and port where it is listening for commands.

Every sentinel maintain a list of other sentinels ID, IP and port.
A sentinel that does no longer announce its presence using Pub/Sub for too
long time is removed from the list. In that case, optionally, a notification
is delivered to the system administrator.

Detection of failing masters
===

An instance is not available from the point of view of Redis Sentinel when
it is no longer able to reply to the PING command correctly for longer than
the specified number of seconds, consecutively.

For a PING reply to be considered valid, one of the following conditions
should be true:

1) PING replied with +PONG.
2) PING replied with -LOADING error.
3) PING replied with -MASTERDOWN error.

What is not considered an acceptable reply:

1) PING replied with -BUSY error.
2) PING replied with -MISCONF error.
3) PING reply not received after more than a specified number of milliseconds.

PING should never reply with a different error code than the ones listed above
but any other error code is considered an acceptable reply by Redis Sentinel.

Handling of -BUSY state
===

The -BUSY error is returned when a script is running for more time than the
configured script time limit. When this happens before triggering a fail over
Redis Sentinel will try to send a "SCRIPT KILL" command, that will only
succeed if the script was read-only.

Agreement with other sentinels
===

Once a Sentinel detects that the master is failing, in order to perform the
fail over, it must make sure that the required number of other sentinels
are agreeing as well.

To do so one sentinel after the other is checked to see if the needed
quorum is reached, as configured by the user.

If the needed level of agreement is reached, the sentinel schedules the
fail over after DELAY seconds, where:

    DELAY = SENTINEL_CARDINALITY * 60

The cardinality of a sentinel is obtained by the sentinel ordering all the
known sentinels, including itself, lexicographically by ID. The first sentinel
has cardinality 0, the second 1, and so forth.

This is useful in order to avoid that multiple sentinels will try to perform
the fail over at the same time.

However if a sentinel will fail for some reason, within 60 seconds the next
one will try to perform the fail over.

Anyway once the delay has elapsed, before performing the fail over, sentinels
make sure using the INFO command that none of the slaves was already switched
into a master by some other sentinel or any other external software
component (or the system administrator itself).

Also the "SENTINEL NEWMASTER" command is send to all the other sentinels
by the sentinel that performed the failover (see later for details).

Slave sanity checks before election
===

Once the fail over process starts, the sentinel performing the slave election
must be sure that the slave is functioning correctly.

A master may have multiple slaves. A suitable candidate must be found.

To do this, a sentinel will check all the salves in the order listed by
Redis in the INFO output (however it is likely that we'll introduce some way
to indicate that a slave is to be preferred to another).

The slave must be functioning correctly (able to reply to PING with one of
the accepted replies), and the INFO command should show that it has been
disconnected by the master for no more than the specified number of seconds
in the Sentinel configuration.

The first slave found to meet this conditions is selected as the candidate
to be elected to master. However to really be selected as a candidate the
configured number of sentinels must also agree on the reachability of the
slave (the sentinel will check this sending SENTINEL STATUS commands).

Fail over process
===

The fail over process consists of the following steps:

1) Check that no slave was already elected.
2) Find suitable slave.
3) Turn the slave into a master using the SLAVEOF NO ONE command.
4) Verify the state of the new master again using INFO.
5) Call an user script to inform the clients that the configuration changed.
6) Call an user script to notify the system administrator.
7) Turn all the remaining slaves, if any, to slaves of the new master.
8) Send a SENTINEL NEWMASTER command to all the reachable sentinels.
0) Start monitoring the new master.

If Steps "1","2" or "3" fail, the fail over is aborted.
If Step "6" fails (the script returns non zero) the new master is contacted again and turned back into a slave of the previous master, and the fail over aborted.

All the other errors are considered to be non-fatal.

SENTINEL NEWMASTER command
==

The SENTINEL NEWMASTER command reconfigures a sentinel to monitor a new master.
The effect is similar of completely restarting a sentinel against a new master.
If a fail over was scheduled by the sentinel it is cancelled as well.

Sentinels monitoring other sentinels
===

When a sentinel no longer advertises itself using the Pub/Sub channel for too
much time (configurable), the other sentinels can send (if configured) a
notification to the system administrator to notify that a sentinel may be down.

At the same time the sentinel is removed from the list of sentinels (but it
will be automatically re-added to this list once it starts advertising itself
again using Pub/Sub).

User provided scripts
===

Sentinels call user-provided scripts to perform two tasks:

1) Inform clients that the configuration changed.
2) Notify the system administrator of problems.

The script to inform clients of a configuration change has the following parameters:

1) ip:port of the calling Sentinel.
2) old master ip:port.
3) new master ip:port.

The script to send notifications is called with the following parameters:

1) ip:port of the calling Sentinel.
2) The message to deliver to the system administrator is passed writing to the standard input.

Using the ip:port of the calling sentinel, scripts may call SENTINEL subcommands
to get more info if needed.

Concrete implementations of notification scripts will likely use the "mail"
command or some other command to deliver SMS messages, emails, twitter direct
messages.

Implementations of the script to modify the configuration in web applications
are likely to use HTTP GET requests to force clients to update the
configuration.

Setup examples
===

Imaginary setup:

    computer A runs the Redis master.
    computer B runs the Reids slave and the client software.

In this naive configuration it is possible to place a single sentinel, with
"minimal agreement" set to the value of one (no acknowledge from other
sentinels needed), running on "B".

If "A" will fail the fail over process will start, the slave will be elected
to master, and the client software will be reconfigured.

Imaginary setup:

    computer A runs the Redis master
    computer B runs the Redis slave
    computer C,D,E,F,G are web servers acting as clients

In this setup it is possible to run five sentinels placed at C,D,E,F,G with
"minimal agreement" set to 3.

In real production environments there is to evaluate how the different
computers are networked together, and to check what happens during net splits
in order to select where to place the sentinels, and the level of minimal
agreement, so that a single arm of the network failing will not trigger a
fail over.

In general if a complex network topology is present, the minimal agreement
should be set to the max number of sentinels existing at the same time in
the same network arm, plus one.


