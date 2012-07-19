Redis Sentinel Documentation
===

Redis Sentinel is a system designed to help managing Redis instances.
It performs the following three tasks:

* **Monitoring**. Sentinel constantly check if your master and slave instances are working as expected.
* **Notification**. Sentinel can notify the system administrator, or another computer program, via an API, that something is wrong with one of the monitored Redis instances.
* **Automatic failover**. If a master is not working as expected, Sentinel can start a failover process where a slave is promoted to master, the other additional slaves are reconfigured to use the new master, and the applications using the Redis server informed about the new address to use when connecting.

Redis Sentinel is a distributed system, this means that usually you want to run
multiple Sentinel processes across your infrastructure, and this processes
will use agreement protocols in order to understand if a master is down and
to perform the failover.

Redis Sentinel is shipped as a stand-alone executable called `redis-sentinel`
but actually it is a special execution mode of the Redis server itself, and
can be also invoked using the `--sentinel` option of the normal `redis-sever`
executable.

**WARNING:** Redis Sentinel is currently a work in progress. This document
describes how to use what we already have and may change as the Sentinel
implementation changes.

Redis Sentinel is compatible with Redis 2.4.16 or greater, and redis 2.6.0-rc6 or greater.

Obtaining Sentinel
===

Currently Sentinel is part of the Redis *unstable* branch at github.
To compile it you need to clone the *unstable* branch and compile Redis.
You'll see a `redis-sentinel` executable in your `src` directory.

Alternatively you can use directly the `redis-server` executable itself,
starting it in Sentinel mode as specified in the next paragraph.

Running Sentinel
===

If you are using the `redis-sentinel` executable (or if you have a symbolic
link with that name to the `redis-server` executable) you can run Sentinel
with the following command line:

    redis-sentinel /path/to/sentinel.conf

Otherwise you can use directly the `redis-server` executable starting it in
Sentinel mode:

    redis-server /path/to/sentine.conf --sentinel

Both ways work the same.

Configuring Sentinel
===

In the root of the Redis source distribution you will find a `sentinel.conf`
file that is a self-documented example configuration file you can use to
configure Sentinel, however a typical minimal configuration file looks like the
following:

    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel down-after-milliseconds mymaster 60000
    sentinel can-failover mymaster yes
    sentinel parallel-syncs mymaster 1

    sentinel monitor mymaster 192.168.1.3 6380 4
    sentinel down-after-milliseconds mymaster 30000
    sentinel can-failover mymaster yes
    sentinel parallel-syncs mymaster 5

The first line is used to tell Redis to monitor a master called *mymaster*,
that is at address 127.0.0.1 and port 6379, with a level of agreement needed
to detect this master as failing of 2 sentinels (if the agreement is not reached
the automatic failover does not start).

The other options are almost always in the form:

    sentinel <option_name> <master_name> <option_value>

And are used for the following purposes:

* `down-after-milliseconds` is the time in milliseconds an instance should not be reachable (either does not reply to our PINGs or it is replying with an error) for a Sentinel starting to think it is down. After this time has elapsed the Sentinel will mark an instance as **subjectively down** (also known as
`SDOWN`), that is not enough to
start the automatic failover. However if enough instances will think that there
is a subjectively down condition, then the instance is marked as
**objectively down**. The number of sentinels that needs to agree depends on
the configured agreement for this master.
* `can-failover` tells this Sentinel if it should start a failover when an
instance is detected as objectively down (also called `ODOWN` for simplicity).
You may configure all the Sentinels to perform the failover if needed, or you
may have a few Sentinels used only to reach the agreement, and a few more
that are actually in charge to perform the failover.
* `parallel-syncs` sets the number of slaves that can be reconfigured to use
the new master after a failover at the same time. The lower the number, the
more time it will take for the failover process to complete, however if the
slaves are configured to serve old data, you may not want all the slaves to
resync at the same time with the new master, as while the replication process
is mostly non blocking for a slave, there is a moment when it stops to load
the bulk data from the master during a resync. You may make sure only one
slave at a time is not reachable by setting this option to the value of 1.

There are more options that are described in the rest of this document and
documented in the example sentinel.conf file.

SDOWN and ODOWN
===

As already briefly mentioned in this document Redis Sentinel has two different
concepts of *being down*, one is called a *Subjectively Down* condition
(SDOWN) and is a down condition that is local to a given Sentinel instance.
Another is called *Objectively Down* condition (ODOWN) and is reached when
enough Sentinels (at least the number configured as the `quorum` parameter
of the monitored master) have an SDOWN condition, and get feedbacks from
other Sentinels using the `SENTINEL is-master-down-by-addr` command.

From the point of view of a Sentienl an SDOWN condition is reached if we
don't receive a valid reply to PING requests for the number of seconds
specified in the configuration as `is-master-down-after-milliseconds`
parameter.

An acceptable reply to PING is one of the following:

* PING replied with +PONG.
* PING replied with -LOADING error.
* PING replied with -MASTERDOWN error.

Any other reply (or no reply) is considered non valid.

Note that SDOWN requires that no acceptable reply is received for the whole
interval configured, so for instance if the interval is 30000 milliseconds
(30 seconds) and we receive an acceptable ping reply every 29 seconds, the
instance is considered to be working.

Sentinels and Slaves auto discovery
===

While Sentinels stay connected with other Sentinels in order to reciprocally
check the availability of each other, and to exchange messages, you don't
need to configure the other Sentinel addresses in every Sentinel instance you
run, as Sentinel uses the Redis master Pub/Sub capabilities in order to
discover the other Sentinels that are monitoring the same master.

This is obtained by sending *Hello Messages* into the channel named
`__sentinel__:hello`.

Similarly you don't need to configure what is the list of the slaves attached
to a master, as Sentinel will auto discover this list querying Redis.

Sentinel commands
===

By default Sentinel runs using TCP port 26379 (note that 6379 is the normal
Redis port). Sentinels accept commands using the Redis protocol, so you can
use `redis-cli` or any other unmodified Redis client in order to talk with
Sentinel.

The following is a list of accepted commands:
* **PING** this command simply returns PONG.
* **SENTINEL masters** show a list of monitored masters and their state.
* **SENTIENL slaves `<master name>`** show a list of slaves for this master, and their state.
* **SENTINEL is-master-down-by-addr `<ip> <port>`** return a two elements multi bulk reply where the first is 0 or 1 (0 if the master with that address is known and is in `SDOWN` state, 1 otherwise). The second element of the reply is the
*subjective leader* for this master, that is, the `runid` of the Redis
Sentinel instance that should perform the failover accordingly to the queried
instance.
* **SENTINEL get-master-addr-by-name `<master name>`** return the ip and port number of the master with that name. If a failover is in progress or terminated successfully for this master it returns the address and port of the promoted slave.
* **SENTINEL reset `<pattern>`** this command will reset all the masters with matching name. The pattern argument is a glob-style pattern. The reset process clears any previous state in a master (including a failover in progress), and removes every slave and sentinel already discovered and associated with the master.

The failover process
===

The failover process consists on the following steps:

* Recognize that the master is in ODOWN state.
* Understand what's the Sentinel that should start the failover, called **The Leader**. All the other Sentinels will be **The Observers**.
* The leader selects a slave to promote to master.
* The promoted slave is turned into a master with the command **SLAVEOF NO ONE**.
* The observers see that a slave was turned into a master, so they know the failover started.
* All the other slaves attached to the original master are configured with the **SLAVEOF** command in order to start the replication process with the new master.
* The leader terminates the failover process when all the slaves are reconfigured. It removes the old master from the table of monitored masters and adds the new master, *under the same name* of the original master.
* The observers detect the end of the failover process when all the slaves are reconfigured. They remove the old master from the table and start monitoring the new master, exactly as the leader does.

The election of the Leader is performed using the same mechanism used to reach
the ODOWN state, that is, the **SENTINEL is-master-down-by-addr** command.
It returns the leader from the point of view of the queried Sentinel, we call
it the **Subjective Leader**, and is selected using the following rule:

* We remove all the Sentinels that can't failover for configuration (this information is propagated using the Hello Channel to all the Sentinels).
* We remove all the Sentinels in SDOWN, disconnected, or with the last ping reply received more than `SENTINEL_INFO_VALIDITY_TIME` milliseconds ago (currently defined as 5 seconds).
* Of all the remaining instances, we get the one with the lowest `runid`, lexicographically (every Redis instance has a Run ID, that is an identifier of every single execution).

For a Sentinel to sense that it is the **Objective Leader**, that is, the Sentinel that should start the failove process, the following conditions are needed.

* It thinks it is the subjective leader itself.
* It reaches acknowledges from other Sentinels about the fact it is the leader: at least 50% plus one of all the Sentinels that were able to reply to the `SENTINEL is-master-down-by-addr` request shoudl agree it is the leader, and additionally we need a total level of agreement at least equal to the configured quorum of the master instance that we are going to failover.

Once a Sentinel things it is the Leader, the failover starts, but there is always a delay of five seconds plus an additional random delay. This is an additional layer of protection because if during this period we see another instance turning a slave into a master, we detect it as another instance staring the failover and turn ourselves as an observer instead.

This is needed because when configuring Sentinel the user is free to select a level of agreement needed that is lower than the majority of instances. This plus a complex netsplit may create the condition for multiple instances to start the failover as a leader at the same time. So the random delay and the detection of another leader are designed to make the process more robust.

End of failover
===

The failover process is considered terminated from the point of view of a
single Sentinel if:

* The promoted slave is not in SDOWN condition.
* A slave was promoted as new master.
* All the other slaves are configured to use the new master.

Note: Slaves that are in SDOWN state are ignored.

Also the failover state is considered terminate if:

* The promoted slave is not in SDOWN condition.
* A slave was promoted as new master.
* At least `failover-timeout` milliseconds elapsed since the last progress.

The `failover-timeout` value can be configured in sentinel.conf for every
different slave.

Note that when a leader terminates a failover for timeout, it sends a
`SLAVEOF` command in a best-effort way to all the slaves yet to be
configured, in the hope that they'll receive the command and replicate
with the new master eventually.

Leader failing during failover
===

If the leader fails when it has yet to promote the slave into a master, and it
fails in a way that makes it in SDOWN state from the point of view of the other
Sentinels, if enough Sentinels remained to reach the quorum the failover
will automatically continue using a new leader (the subjective leader of
all the remaining Sentinels will change because of the SDOWN state of the
previous leader).

If the failover was already in progress and the slave
was already promoted, and possibly a few other slaves were already reconfigured,
an observer that is the new objective leader will continue the failover in
case no progresses are made for more than 25% of the time specified by the
`failover-timeout` configuration option.

Note that this is safe as multiple Sentinels trying to reconfigure slaves
with duplicated SLAVEOF commands do not create any race condition, but at the
same time we want to be sure that all the slaves are reconfigured in the
case the original leader is no longer ok.

Promoted slave failing during failover
===

If the promoted slave has an active SDOWN condition, a Sentinel will never
sense the failover as terminated.

Additionally if there is an *extended SDOWN condition* (that is an SDOWN that
lasts for more than `down-after-milliseconds` milliseconds) the failover is
aborted (this happens for leaders and observers), and the master starts to
be monitored again as usually, so that a new failover can start with a different
slave.

Note that when this happens it is possible that there are a few slaves already
configured to replicate from the (now failing) promoted slave, so when the
leader sentinel aborts a failover it sends a `SLAVEOF` command to all the
slaves already reconfigured or in the process of being reconfigured to switch
the configuration back to the original master.

Manual interactions
===

TODO:

* TODO: Manually triggering a failover with SENTINEL FAILOVER.
* Pausing Sentinels with PAUSE, GPAUSE, RESUME, GRESUME.
* Using REDIS SENTINEL

The failback process
===

TODO:

* Sentinel does not perform automatic Failback.
* Step for the failback: attach the old master as slave, run the failover.

Clients configuration update
===

Notifications
===

Suggested setup
===

TILT mode
===


