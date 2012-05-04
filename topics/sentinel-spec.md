Redis Sentinel design draft 1.1
===

Changelog:

* 1.0 first version.
* 1.1 fail over steps modified: slaves are pointed to new master one after the other and not simultaneously. New section about monitoring slaves to ensure they are replicating correctly.
* 1.2 Fixed a typo in the fail over section about: critical error is in step 5 and not 6. Added TODO section.

Introduction
===

This document provides an overview of the motivation for, and the design of, the 'Redis Sentinel'.

Redis Sentinel' is a Redis high availability solution for Redis that is
currently under development. It should be noted that this solution is not in anyway related to to Redis Cluster: it is
simply intended as a viable option for high availability use-cases that require automatic detection 
and failover of a single faulty master instance.

The projected delivery plan is to provide a usable beta implementation of Redis Sentinel in a
short time, preferably by mid June 2012.

In short this is what Redis Sentinel will be able to do:

* Monitor master instances to see if they are available.
* Promote a slave to master when the master fails.
* Modify clients configurations when a slave is elected.
* Inform the system administrator about incidents using notifications.

Redis Sentinel idea
===

The idea of Redis Sentinel is to have multiple "monitoring devices" in
different places of your network, monitoring a designated Redis master instance.

However these independent devices can't act without agreement with other
sentinels.

For the fail-over process to start, a reliable mechanism for the detection of a faulty 
Redis master instance is necessary.  The sentinels fulfill that role by monitoring 
the master instance, and employ a configurable consensus strategy for determining system health.

The number of the sentinels, their location in the network, and the
degree of "minimal agreement" to arrive at consensus, all affect the overall behavior among many
possibilities.  These are the configuration options for Redis Sentinel.

Redis Sentinel does not use proxies: Redis client reconfigurations are performed
by running user-provided executables -- for example a shell script or a
Python program -- in a user setup specific way.

In what form it will be shipped
===

Redis Sentinel is simply a special execution mode of the redis-server executable:

Executing the redis-server with "redis-sentinel" as argv[0] (for instance
using a symbolic link or copying the file), or, the --sentinel command-line option,
will start the Redis instance in sentinel mode.

A redis-server in sentinel mode will only respond to Redis Sentinel
commands. All the other commands will be refused.

The entirety of sentinel related code will be isolated in a separated file sentinel.c
and will have minimal impact on the rest of the code base. This approach still allows
a sentinel to fully use all the facilities already implemented inside Redis without any need
to re-implement them or to maintain a separated code base for Redis Sentinel.

Sentinel networking
===

All the sentinels will maintain a connection with the monitored master.

Sentinels use the Redis protocol to talk with each other when needed.

Redis Sentinels export a single SENTINEL command. Subcommands of the SENTINEL
command are used in order to perform different actions.

For instance to check what a sentinel thinks about the state of the master
it is possible to send the "SENTINEL STATUS" command using redis-cli.

Interactions between the Redis Sentinel instances is minimal and not chatty. A sentinel instance will query
other instances only when an agreement is needed about the state of the master or slaves.

The list of networking tasks performed by every sentinel is the following:

* A Sentinel accepts commands using a TCP port.
* A Sentinel periodically sends PUBLISH to advertise its presence using the master Pub/Sub.  Period is one minute.
* A Sentinel periodically sends INFO to the master in order to take a fresh list of connected slaves. Period is one minute.
* A Sentinel periodically sends PING to the reeds master and slave instances to monitor their health.  
* A Sentinel will subscribe to the sentinels Pub/SUb channel in order to discover newly connected sentinels. (See PUBLISH above.)

Sentinel presence and discovery
===

Sentinels do not use peer-to-peer interconnect. 

But clearly they will need to know the IP address and port of
other peer sentinel instances, because this is necessary for a robust agreement
protocol to fulfill the required functionality e.g. slave election and promotion.

To make the configuration of sentinels as simple as possible, Redis Sentinels leverage 
the existing Pub/Sub functionality, via the Redis master instance. 

A single channel is used to support the presence and discovery protocol. Every sentinel 
will subscribe to the this channel and also use it to convey information to its peers.

A sentinel instance will advertise its presence via broadcasts to this channel.
This presence advertisement includes the "Run ID" of the Sentinel,
and the IP address and port where it listens for commands.

In addition, each sentinel instance will maintain a list of other known sentinels 
and their associated properties such as ID, IP and port.

A sentinel must periodically re-assert its presence to its peers.  

A sentinel that fails to assert its presence using Pub/Sub (within a given time window) 
is removed from the list of known peer sentinels that is maintained by its peers. In this 
case, optionally, a notification is delivered to the system administrator. (See user defined scripts below.)

Detection of failing masters
===

An instance is not available from the point of view of Redis Sentinel when
it is no longer able to reply to the PING command correctly for longer than
the specified number of seconds, consecutively.

For a PING reply to be considered valid, one of the following conditions
should be true:

* PING replied with +PONG.
* PING replied with -LOADING error.
* PING replied with -MASTERDOWN error.

Invalid replies are:

* PING replied with -BUSY error.
* PING replied with -MISCONF error.
* PING reply not received after more than a specified number of milliseconds.

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
are in agreement with its failure diagnosis.

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

* 1) Check that no slave was already elected.
* 2) Find suitable slave.
* 3) Turn the slave into a master using the SLAVEOF NO ONE command.
* 4) Verify the state of the new master again using INFO.
* 5) Call a user script to inform the clients that the configuration changed.
* 6) Call a user script to notify the system administrator.
* 7) Send a SENTINEL NEWMASTER command to all the reachable sentinels.
* 8) Turn all the remaining slaves, if any, to slaves of the new master. This is done incrementally, one slave after the other, waiting for the previous slave to complete the synchronization process before starting with the next one.
* 9) Start monitoring the new master.

If Steps "1","2" or "3" fail, the fail over is aborted.
If Step "5" fails (the script returns non zero) the new master is contacted again and turned back into a slave of the previous master, and the fail over aborted.

All the other errors are considered to be non-fatal.

SENTINEL NEWMASTER command
==

The SENTINEL NEWMASTER command reconfigures a sentinel to monitor a new master.
The effect is similar of completely restarting a sentinel against a new master.
If a fail over was scheduled by the sentinel it is cancelled as well.

Slaves monitoring
===

A successful fail over can be only performed if there is at least one slave
that contains a reasonably update version of the master dataset.
We perform this check before electing the slave using the INFO command
to check how many seconds elapsed since master and slave disconnected.

However if there is a problem in the replication process (networking problem,
redis bug, a problem with the slave operating system, ...), when the master
fail, we can be in the unhappy condition of not having any slave that's good
enough for the fail over.

For this reason every sentinel also continuously monitors slaves as well,
checking if the replication is up. If the replication appears to be failing
(taking longer than a configurable time window), a notification is sent to the system
administrator alerting them to that fact and that they should make sure 
that slaves are correctly configured and operational.

Sentinels monitoring other sentinels
===

When a sentinel no longer advertises itself using the Pub/Sub channel (taking 
longer than a configurable time window), the other sentinels can send (if configured) 
a notification to the system administrator to notify that a sentinel may be down.

At the same time the sentinel is removed from the list of sentinels (but it
will be automatically re-added to this list once it starts advertising itself
again using Pub/Sub).

User provided scripts
===

Sentinels call user-provided scripts to perform two tasks:

* Inform clients that the configuration changed.
* Notify the system administrator of problems.

The script to inform clients of a configuration change has the following parameters:

* ip:port of the calling Sentinel.
* old master ip:port.
* new master ip:port.

The script to send notifications is called with the following parameters:

* ip:port of the calling Sentinel.
* The message to deliver to the system administrator is passed writing to the standard input.

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

TODO
===

* More detailed specification of user script error handling, including what return codes may mean, like 0: try again. 1: fatal error. 2: try again, and so forth.
* More detailed specification of what happens when an user script does not return in a given amount of time.
* Add a "push" notification system for configuration changes.
* Consider adding a "name" to every set of slaves / masters, so that clients can identify services by name.
* Make clear that we handle a single Sentinel monitoring multiple masters.
* Make clear the configuration for sentinel PING heartbeat period.
