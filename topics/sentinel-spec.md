**WARNING:** this document is no longer in sync with the implementation of Redis Sentinel and will be removed in the next weeks.

Redis Sentinel design draft 1.3
===

Changelog:

* 1.0 first version.
* 1.1 fail over steps modified: slaves are pointed to new master one after the other and not simultaneously. New section about monitoring slaves to ensure they are replicating correctly.
* 1.2 Fixed a typo in the fail over section about: critical error is in step 5 and not 6. Added TODO section.
* 1.3 Document updated to reflect the actual implementation of the monitoring and leader election.

Introduction
===

Redis Sentinel is the name of the Redis high availability solution that's
currently under development. It has nothing to do with Redis Cluster and
is intended to be used by people that don't need Redis Cluster, but simply
a way to perform automatic fail over when a master instance is not functioning
correctly.

The plan is to provide a usable beta implementation of Redis Sentinel in a
short time, preferably in mid July 2012.

In short this is what Redis Sentinel will be able to do:

* Monitor master and slave instances to see if they are available.
* Promote a slave to master when the master fails.
* Modify clients configurations when a slave is elected.
* Inform the system administrator about incidents using notifications.

So the three different roles of Redis Sentinel can be summarized in the following three big aspects:

* Monitoring.
* Notification.
* Automatic failover.

The following document explains what is the design of Redis Sentinel in order
to accomplish this goals.

Redis Sentinel idea
===

The idea of Redis Sentinel is to have multiple "monitoring devices" in
different places of your network, monitoring the Redis master instance.

However this independent devices can't act without agreement with other
sentinels.

Once a Redis master instance is detected as failing, for the failover process
to start, the sentinel must verify that there is a given level of agreement.

The amount of sentinels, their location in the network, and the
configured quorum, select the desired behavior among many possibilities.

Redis Sentinel does not use any proxy: clients reconfiguration is performed
running user-provided executables (for instance a shell script or a
Python program) in a user setup specific way.

In what form it will be shipped
===

Redis Sentinel is just a special mode of the redis-server executable.

If the redis-server is called with "redis-sentinel" as `argv[0]` (for instance
using a symbolic link or copying the file), or if --sentinel option is passed,
the Redis instance starts in sentinel mode and will only understand sentinel
related commands. All the other commands will be refused.

The whole implementation of sentinel will live in a separated file sentinel.c
with minimal impact on the rest of the code base. However this solution allows
to use all the facilities already implemented inside Redis without any need
to reimplement them or to maintain a separated code base for Redis Sentinel.

Sentinels networking
===

All the sentinels take persistent connections with:

* The monitored masters.
* All its slaves, that are discovered using the master's INFO output.
* All the other Sentinels connected to this master, discovered via Pub/Sub.

Sentinels use the Redis protocol to talk with each other, and to reply to
external clients.

Redis Sentinels export a SENTINEL command. Subcommands of the SENTINEL
command are used in order to perform different actions.

For instance the `SENTINEL masters` command enumerates all the monitored
masters and their states. However Sentinels can also reply to the PING command
as a normal Redis instance, so that it is possible to monitor a Sentinel
considering it a normal Redis instance.

The list of networking tasks performed by every sentinel is the following:

* A Sentinel PUBLISH its presence using the master Pub/Sub multiple times every five seconds.
* A Sentinel accepts commands using a TCP port. By default the port is 26379.
* A Sentinel constantly monitors masters, slaves, other sentinels sending PING commands.
* A Sentinel sends INFO commands to the masters and slaves every ten seconds in order to take a fresh list of connected slaves, the state of the master, and so forth.
* A Sentinel monitors the sentinel Pub/Sub "hello" channel in order to discover newly connected Sentinels, or to detect no longer connected Sentinels. The channel used is `__sentinel__:hello`.

Sentinels discovering
===

To make the configuration of sentinels as simple as possible every sentinel
broadcasts its presence using the Redis master Pub/Sub functionality.

Every sentinel is subscribed to the same channel, and broadcast information
about its existence to the same channel, including the Run ID of the Sentinel,
and the IP address and port where it is listening for commands.

Every sentinel maintains a list of other sentinels Run ID, IP and port.
A sentinel that does no longer announce its presence using Pub/Sub for too
long time is removed from the list, assuming the Master appears to be working well. In that case a notification is delivered to the system administrator.

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

What is not considered an acceptable reply:

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

Subjectively down and Objectively down
===

From the point of view of a Sentinel there are two different error conditions for a master:

* *Subjectively Down* (aka `S_DOWN`) means that a master is down from the point of view of a Sentinel.
* *Objectively Down* (aka `O_DOWN`) means that a master is subjectively down from the point of view of enough Sentinels to reach the configured quorum for that master.

How Sentinels agree to mark a master `O_DOWN`.
===

Once a Sentinel detects that a master is in `S_DOWN` condition it starts to
send other sentinels a `SENTINEL is-master-down-by-addr` request every second.
The reply is stored inside the state that every Sentinel takes in memory.

Ten times every second a Sentinel scans the state and checks if there are
enough Sentinels thinking that a master is down (this is not specific for
this operation, most state checks are performed with this frequency).

If this Sentinel has already an `S_DOWN` condition for this master, and there
are enough other sentinels that recently reported this condition
(the validity time is currently set to 5 seconds), then the master is marked
as `O_DOWN` (Objectively Down).

Note that the `O_DOWN` state is not propagated among Sentinels. Every single
Sentinel can reach independently this state.

The SENTINEL is-master-down-by-addr command
===

Sentinels ask other Sentinels for the state of a master from their local point
of view using the `SENTINEL is-master-down-by-addr` command. This command
replies with a boolean value (in the form of a 0 or 1 integer reply, as
a first element of a multi bulk reply).

However in order to avoid false positives, the command acts in the following
way:

* If the specified ip and port is not known, 0 is returned.
* If the specified ip and port are found but don't belong to a Master instance, 0 is returned.
* If the Sentinel is in TILT mode (see later in this document) 0 is returned.
* The value of 1 is returned only if the instance is known, is a master, is flagged `S_DOWN` and the Sentinel is in TILT mode.

Duplicate Sentinels removal
===

In order to reach the configured quorum we absolutely want to make sure that
the quorum is reached by different physical Sentinel instances. Under
no circumstance we should get agreement from the same instance that for some
reason appears to be two or multiple distinct Sentinel instances.

This is enforced by an aggressive removal of duplicated Sentinels: every time
a Sentinel sends a message in the Hello Pub/Sub channel with its address
and runid, if we can't find a perfect match (same runid and address) inside
the Sentinels table for that master, we remove any other Sentinel with the same
runid OR the same address. And later add the new Sentinel.

For instance if a Sentinel instance is restarted, the Run ID will be different,
and the old Sentinel with the same IP address and port pair will be removed.

Starting the failover: Leaders and Observers
===

The fact that a master is marked as `O_DOWN` is not enough to star the
failover process. What Sentinel should start the failover is also to be
decided.

Also Sentinels can be configured in two ways: only as monitors that can't
perform the fail over, or as Sentinels that can start the failover.

What is desirable is that only a Sentinel will start the failover process,
and this Sentinel should be selected among the Sentinels that are allowed
to perform the failover.

In Sentinel there are two roles during a fail over:

* The Leader Sentinel is the one selected to perform the failover.
* The Observers Sentinels are the other sentinels just following the failover process without doing active operations.

So the condition to start the failover is:

* A Master in `O_DOWN` condition.
* A Sentinel that is elected Leader.

Leader Sentinel election
===

The election process works as follows:

* Every Sentinel with a master in `O_DOWN` condition updates its internal state with frequency of 10 HZ to refresh what is the *Subjective Leader* from its point of view.

A Subjective Leader is selected in this way by every sentinel.

* Every Sentinel we know about a given master, that is reachable (no `S_DOWN` state), that is allowed to perform the failover (this Sentinel-specific configuration is propagated using the Hello channel), is a possible candidate.
* Among all the possible candidates, the one with lexicographically smaller Run ID is selected.

Every time a Sentinel replies with to the `MASTER is-sentinel-down-by-addr` command it also replies with the Run ID of its Subjective Leader.

Every Sentinel with a failing master (`O_DOWN`) checks its subjective leader
and the subjective leaders of all the other Sentinels with a frequency of
10 HZ, and will flag itself as the Leader if the following conditions happen:

* It is the Subjective Leader of itself.
* At least N-1 other Sentinels that see the master as down, and are reachable, also think that it is the Leader. With N being the quorum configured for this master.
* At least 50% + 1 of all the Sentinels involved in the voting process (that are reachable and that also see the master as failing) should agree on the Leader.

So for instance if there are a total of three sentinels, the master is failing,
and all the three sentinels are able to communicate (no Sentinel is failing)
and the configured quorum for this master is 2, a Sentinel will feel itself
an Objective Leader if at least it and another Sentinel is agreeing that
it is the subjective leader.

Once a Sentinel detects that it is the objective leader, it flags the master
with `FAILOVER_IN_PROGRESS` and `IM_THE_LEADER` flags, and starts the failover
process in `SENTINEL_FAILOVER_DELAY` (5 seconds currently) plus a random
additional time between 0 milliseconds and 10000 milliseconds.

During that time we ask INFO to all the slaves with an increased frequency
of one time per second (usually the period is 10 seconds). If a slave is
turned into a master in the meantime the failover is suspended and the
Leader clears the `IM_THE_LEADER` flag to turn itself into an observer.

Guarantees of the Leader election process
===

As you can see for a Sentinel to become a leader the majority is not strictly
required. A user can force the majority to be needed just setting the master
quorum to, for instance, the value of 5 if there are a total of 9 sentinels.

However it is also possible to set the quorum to the value of 2 with 9
sentinels in order to improve the resistance to netsplits or failing Sentinels
or other error conditions. In such a case the protection against race
conditions (multiple Sentinels starting to perform the fail over at the same
time) is given by the random delay used to start the fail over, and the
continuous monitor of the slave instances to detect if another Sentinel
(or a human) started the failover process.

Moreover the slave to promote is selected using a deterministic process to
minimize the chance that two different Sentinels with full vision of the
working slaves may pick two different slaves to promote.

However it is possible to easily imagine netsplits and specific configurations
where two Sentinels may start to act as a leader at the same time, electing two
different slaves as masters, in two different parts of the net that can't
communicate. The Redis Sentinel user should evaluate the network topology and
select an appropriate quorum considering his or her goals and the different
trade offs.

How observers understand that the failover started
===

An observer is just a Sentinel that does not believe to be the Leader, but
still sees a master in `O_DOWN` condition.

The observer is still able to follow and update the internal state based on
what is happening with the failover, but does not directly rely on the
Leader to communicate with it to be informed by progresses. It simply observes
the state of the slaves to understand what is happening.

Specifically the observers flags the master as `FAILOVER_IN_PROGRESS` if a slave
attached to a master turns into a master (observers can see it in the INFO output). An observer will also consider the failover complete once all the other
reachable slaves appear to be slaves of this slave that was turned into a
master.

If a Slave is in `FAILOVER_IN_PROGRESS` and the failover is not progressing for
too much time, and at the same time the other Sentinels start claiming that
this Sentinel is the objective leader (because for example the old leader
is no longer reachable), the Sentinel will flag itself as `IM_THE_LEADER` and
will proceed with the failover.

Note: all the Sentinel state, including the subjective and objective leadership
is a dynamic process that is continuously refreshed with period of 10 HZ.
There is no "one time decision" step in Sentinel.

Selection of the Slave to promote
===

If a master has multiple slaves, the slave to promote to master is selected
checking the slave priority (a new configuration option of Redis instances
that is propagated via INFO output), and picking the one with lower priority
value (it is an integer similar to the one of the MX field of the DNS system).
All the slaves that appears to be disconnected from the master for a long
time are discarded (stale data).

If slaves with the same priority exist, the one with the lexicographically
smaller Run ID is selected.

If there is no Slave to select because all the salves are failing the failover
is not started at all. Instead if there is no Slave to select because the
master *never* used to have slaves in the monitoring session, then the
failover is performed nonetheless just calling the user scripts.
However for this to happen a special configuration option must be set for
that master (force-failover-without-slaves).

This is useful because there are configurations where a new Instance can be
provisioned at IP protocol level by the script, but there are no attached
slaves.

Fail over process
===

The fail over process consists of the following steps:

* 1) Turn the selected slave into a master using the SLAVEOF NO ONE command.
* 2) Turn all the remaining slaves, if any, to slaves of the new master. This is done incrementally, one slave after the other, waiting for the previous slave to complete the synchronization process before starting with the next one.
* 3) Call a user script to inform the clients that the configuration changed.
* 4) Completely remove the old failing master from the table, and add the new master with the same name.

If Steps "1" fails, the fail over is aborted.

All the other errors are considered to be non-fatal.

TILT mode
===

Redis Sentinel is heavily dependent on the computer time: for instance in
order to understand if an instance is available it remembers the time of the
latest successful reply to the PING command, and compares it with the current
time to understand how old it is.

However if the computer time changes in an unexpected way, or if the computer
is very busy, or the process blocked for some reason, Sentinel may start to
behave in an unexpected way.

The TILT mode is a special "protection" mode that a Sentinel can enter when
something odd is detected that can lower the reliability of the system.
The Sentinel timer interrupt is normally called 10 times per second, so we
expect that more or less 100 milliseconds will elapse between two calls
to the timer interrupt.

What a Sentinel does is to register the previous time the timer interrupt
was called, and compare it with the current call: if the time difference
is negative or unexpectedly big (2 seconds or more) the TILT mode is entered
(or if it was already entered the exit from the TILT mode postponed).

When in TILT mode the Sentinel will continue to monitor everything, but:

* It stops acting at all.
* It starts to reply negatively to `SENTINEL is-master-down-by-addr` requests as the ability to detect a failure is no longer trusted.

If everything appears to be normal for 30 second, the TILT mode is exited.

Sentinels monitoring other sentinels
===

When a sentinel no longer advertises itself using the Pub/Sub channel for too
much time (30 minutes more the configured timeout for the master), but at the
same time the master appears to work correctly, the Sentinel is removed from
the table of Sentinels for this master, and a notification is sent to the
system administrator. 

User provided scripts
===

Sentinels can optionally call user-provided scripts to perform two tasks:

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
command or some other command to deliver SMS messages, emails, tweets.

Implementations of the script to modify the configuration in web applications
are likely to use HTTP GET requests to force clients to update the
configuration, or any other sensible mechanism for the specific setup in use.

Setup examples
===

Imaginary setup:

    computer A runs the Redis master.
    computer B runs the Redis slave and the client software.

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

SENTINEL SUBCOMMANDS
===

* `SENTINEL masters`, provides a list of configured masters.
* `SENTINEL slaves <master name>`, provides a list of slaves for the master with the specified name.
* `SENTINEL sentinels <master name>`, provides a list of sentinels for the master with the specified name.
* `SENTINEL is-master-down-by-addr <ip> <port>`, returns a two elements multi bulk reply where the first element is :0 or :1, and the second is the Subjective Leader for the failover.

TODO
===

* More detailed specification of user script error handling, including what return codes may mean, like 0: try again. 1: fatal error. 2: try again, and so forth.
* More detailed specification of what happens when a user script does not return in a given amount of time.
* Add a "push" notification system for configuration changes.
* Document that for every master monitored the configuration specifies a name for the master that is reported by all the SENTINEL commands.
* Make clear that we handle a single Sentinel monitoring multiple masters.
