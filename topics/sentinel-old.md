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
describes how to use what we is already implemented, and may change as the
Sentinel implementation evolves.

Redis Sentinel is compatible with Redis 2.4.16 or greater, and redis 2.6.0-rc6 or greater.

Obtaining Sentinel
---

Currently Sentinel is part of the Redis *unstable* branch at GitHub.
To compile it you need to clone the *unstable* branch and compile Redis.
You'll see a `redis-sentinel` executable in your `src` directory.

Alternatively you can use directly the `redis-server` executable itself,
starting it in Sentinel mode as specified in the next paragraph.

Running Sentinel
---

If you are using the `redis-sentinel` executable (or if you have a symbolic
link with that name to the `redis-server` executable) you can run Sentinel
with the following command line:

    redis-sentinel /path/to/sentinel.conf

Otherwise you can use directly the `redis-server` executable starting it in
Sentinel mode:

    redis-server /path/to/sentinel.conf --sentinel

Both ways work the same.

Configuring Sentinel
---

The Redis source distribution contains a file called `sentinel.conf`
that is a self-documented example configuration file you can use to
configure Sentinel, however a typical minimal configuration file looks like the
following:

    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel down-after-milliseconds mymaster 60000
    sentinel failover-timeout mymaster 900000
    sentinel can-failover mymaster yes
    sentinel parallel-syncs mymaster 1

    sentinel monitor resque 192.168.1.3 6380 4
    sentinel down-after-milliseconds resque 10000
    sentinel failover-timeout resque 900000
    sentinel can-failover resque yes
    sentinel parallel-syncs resque 5

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

The other options are described in the rest of this document and
documented in the example sentinel.conf file shipped with the Redis
distribution.

SDOWN and ODOWN
---

As already briefly mentioned in this document Redis Sentinel has two different
concepts of *being down*, one is called a *Subjectively Down* condition
(SDOWN) and is a down condition that is local to a given Sentinel instance.
Another is called *Objectively Down* condition (ODOWN) and is reached when
enough Sentinels (at least the number configured as the `quorum` parameter
of the monitored master) have an SDOWN condition, and get feedback from
other Sentinels using the `SENTINEL is-master-down-by-addr` command.

From the point of view of a Sentinel an SDOWN condition is reached if we
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

The ODOWN condition **only applies to masters**. For other kind of instances
Sentinel don't require any agreement, so the ODOWN state is never reached
for slaves and other sentinels.

The behavior of Redis Sentinel can be described by a set of rules that every
Sentinel follows. The complete behavior of Sentinel as a distributed system
composed of multiple Sentinels only results from this rules followed by
every single Sentinel instance. The following is the first set of rules.
In the course of this document more rules will be added in the appropriate
sections.

**Sentinel Rule #1**: Every Sentinel sends a **PING** request to every known master, slave, and sentinel instance, every second.

**Sentinel Rule #2**: An instance is Subjectively Down (**SDOWN**) if the latest valid reply to **PING** was received more than `down-after-milliseconds` milliseconds ago. Acceptable PING replies are: +PONG, -LOADING, -MASTERDOWN.

**Sentinel Rule #3**: Every Sentinel is able to reply to the command **SENTINEL is-master-down-by-addr `<ip> <port>`**. This command replies true if the specified address is the one of a master instance, and the master is in **SDOWN** state.

**Sentinel Rule #4**: If a master is in **SDOWN** condition, every other Sentinel also monitoring this master, is queried for confirmation of this state, every second, using the **SENTINEL is-master-down-by-addr** command.

**Sentinel Rule #5**: If a master is in **SDOWN** condition, and enough other Sentinels (to reach the configured quorum) agree about the condition, with a reply to **SENTINEL is-master-down-by-addr** that is no older than five seconds, then the master is marked as Objectively Down (**ODOWN**).

**Sentinel Rule #6**: Every Sentinel sends an **INFO** request to every known master and slave instance, one time every 10 seconds. If a master is in **ODOWN** condition, its slaves are asked for **INFO** every second instead of being asked every 10 seconds.

**Sentinel Rule #7**: If the **first** INFO reply a Sentinel receives about a master shows that it is actually a slave, Sentinel will update the configuration to actually monitor the master reported by the INFO output instead. So it is safe to start Sentinel against slaves.

Sentinels and Slaves auto discovery
---

While Sentinels stay connected with other Sentinels in order to reciprocally
check the availability of each other, and to exchange messages, you don't
need to configure the other Sentinel addresses in every Sentinel instance you
run, as Sentinel uses the Redis master Pub/Sub capabilities in order to
discover the other Sentinels that are monitoring the same master.

This is obtained by sending *Hello Messages* into the channel named
`__sentinel__:hello`.

Similarly you don't need to configure what is the list of the slaves attached
to a master, as Sentinel will auto discover this list querying Redis.

**Sentinel Rule #8**: Every Sentinel publishes a message to every monitored master Pub/Sub channel `__sentinel__:hello`, every five seconds, announcing its presence with ip, port, runid, and ability to failover (accordingly to `can-failover` configuration directive in `sentinel.conf`).

**Sentinel Rule #9**: Every Sentinel is subscribed to the Pub/Sub channel `__sentinel__:hello` of every master, looking for unknown sentinels. When new sentinels are detected, we add them as sentinels of this master.

**Sentinel Rule #10**: Before adding a new sentinel to a master a Sentinel always checks if there is already a sentinel with the same runid or the same address (ip and port pair). In that case all the matching sentinels are removed, and the new added.

Sentinel API
===

By default Sentinel runs using TCP port 26379 (note that 6379 is the normal
Redis port). Sentinels accept commands using the Redis protocol, so you can
use `redis-cli` or any other unmodified Redis client in order to talk with
Sentinel.

There are two ways to talk with Sentinel: it is possible to directly query
it to check what is the state of the monitored Redis instances from its point
of view, to see what other Sentinels it knows, and so forth.

An alternative is to use Pub/Sub to receive *push style* notifications from
Sentinels, every time some event happens, like a failover, or an instance
entering an error condition, and so forth.

Sentinel commands
---

The following is a list of accepted commands:

* **PING** this command simply returns PONG.
* **SENTINEL masters** show a list of monitored masters and their state.
* **SENTINEL slaves `<master name>`** show a list of slaves for this master, and their state.
* **SENTINEL is-master-down-by-addr `<ip> <port>`** return a two elements multi bulk reply where the first is 0 or 1 (0 if the master with that address is known and is in `SDOWN` state, 1 otherwise). The second element of the reply is the
*subjective leader* for this master, that is, the `runid` of the Redis
Sentinel instance that should perform the failover accordingly to the queried
instance.
* **SENTINEL get-master-addr-by-name `<master name>`** return the ip and port number of the master with that name. If a failover is in progress or terminated successfully for this master it returns the address and port of the promoted slave.
* **SENTINEL reset `<pattern>`** this command will reset all the masters with matching name. The pattern argument is a glob-style pattern. The reset process clears any previous state in a master (including a failover in progress), and removes every slave and sentinel already discovered and associated with the master.

Pub/Sub Messages
---

A client can use a Sentinel as it was a Redis compatible Pub/Sub server
(but you can't use `PUBLISH`) in order to `SUBSCRIBE` or `PSUBSCRIBE` to
channels and get notified about specific events.

The channel name is the same as the name of the event. For instance the
channel named `+sdown` will receive all the notifications related to instances
entering an `SDOWN` condition.

To get all the messages simply subscribe using `PSUBSCRIBE *`.

The following is a list of channels and message formats you can receive using
this API. The first word is the channel / event name, the rest is the format of the data.

Note: where *instance details* is specified it means that the following arguments are provided to identify the target instance:

    <instance-type> <name> <ip> <port> @ <master-name> <master-ip> <master-port>

The part identifying the master (from the @ argument to the end) is optional
and is only specified if the instance is not a master itself.

* **+reset-master** `<instance details>` -- The master was reset.
* **+slave** `<instance details>` -- A new slave was detected and attached.
* **+failover-state-reconf-slaves** `<instance details>` -- Failover state changed to `reconf-slaves` state.
* **+failover-detected** `<instance details>` -- A failover started by another Sentinel or any other external entity was detected (An attached slave turned into a master).
* **+slave-reconf-sent** `<instance details>` -- The leader sentinel sent the `SLAVEOF` command to this instance in order to reconfigure it for the new slave.
* **+slave-reconf-inprog** `<instance details>` -- The slave being reconfigured showed to be a slave of the new master ip:port pair, but the synchronization process is not yet complete.
* **+slave-reconf-done** `<instance details>` -- The slave is now synchronized with the new master.
* **-dup-sentinel** `<instance details>` -- One or more sentinels for the specified master were removed as duplicated (this happens for instance when a Sentinel instance is restarted).
* **+sentinel** `<instance details>` -- A new sentinel for this master was detected and attached.
* **+sdown** `<instance details>` -- The specified instance is now in Subjectively Down state.
* **-sdown** `<instance details>` -- The specified instance is no longer in Subjectively Down state.
* **+odown** `<instance details>` -- The specified instance is now in Objectively Down state.
* **-odown** `<instance details>` -- The specified instance is no longer in Objectively Down state.
* **+failover-takedown** `<instance details>` -- 25% of the configured failover timeout has elapsed, but this sentinel can't see any progress, and is the new leader. It starts to act as the new leader reconfiguring the remaining slaves to replicate with the new master.
* **+failover-triggered** `<instance details>` -- We are starting a new failover as a the leader sentinel.
* **+failover-state-wait-start** `<instance details>` -- New failover state is `wait-start`: we are waiting a fixed number of seconds, plus a random number of seconds before starting the failover.
* **+failover-state-select-slave** `<instance details>` -- New failover state is `select-slave`: we are trying to find a suitable slave for promotion.
* **no-good-slave** `<instance details>` -- There is no good slave to promote. Currently we'll try after some time, but probably this will change and the state machine will abort the failover at all in this case.
* **selected-slave** `<instance details>` -- We found the specified good slave to promote.
* **failover-state-send-slaveof-noone** `<instance details>` -- We are trying to reconfigure the promoted slave as master, waiting for it to switch.
* **failover-end-for-timeout** `<instance details>` -- The failover terminated for timeout. If we are the failover leader, we sent a *best effort* `SLAVEOF` command to all the slaves yet to reconfigure.
* **failover-end** `<instance details>` -- The failover terminated with success. All the slaves appears to be reconfigured to replicate with the new master.
* **switch-master** `<master name> <oldip> <oldport> <newip> <newport>` -- We are starting to monitor the new master, using the same name of the old one. The old master will be completely removed from our tables.
* **failover-abort-x-sdown** `<instance details>` -- The failover was undone (aborted) because the promoted slave appears to be in extended SDOWN state.
* **-slave-reconf-undo** `<instance details>` -- The failover aborted so we sent a `SLAVEOF` command to the specified instance to reconfigure it back to the original master instance.
* **+tilt** -- Tilt mode entered.
* **-tilt** -- Tilt mode exited.

Sentinel failover
===

The failover process consists on the following steps:

* Recognize that the master is in ODOWN state.
* Understand who is the Sentinel that should start the failover, called **The Leader**. All the other Sentinels will be **The Observers**.
* The leader selects a slave to promote to master.
* The promoted slave is turned into a master with the command **SLAVEOF NO ONE**.
* The observers see that a slave was turned into a master, so they know the failover started. **Note:** this means that any event that turns one of the slaves of a monitored master into a master (`SLAVEOF NO ONE` command) will be sensed as the start of a failover process.
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

For a Sentinel to sense to be the **Objective Leader**, that is, the Sentinel that should start the failover process, the following conditions are needed.

* It thinks it is the subjective leader itself.
* It receives acknowledges from other Sentinels about the fact it is the leader: at least 50% plus one of all the Sentinels that were able to reply to the `SENTINEL is-master-down-by-addr` request should agree it is the leader, and additionally we need a total level of agreement at least equal to the configured quorum of the master instance that we are going to failover.

Once a Sentinel things it is the Leader, the failover starts, but there is always a delay of five seconds plus an additional random delay. This is an additional layer of protection because if during this period we see another instance turning a slave into a master, we detect it as another instance staring the failover and turn ourselves into an observer instead. This is just a redundancy layer and should in theory never happen.

**Sentinel Rule #11**: A **Good Slave** is a slave with the following requirements:
* It is not in SDOWN nor in ODOWN condition.
* We have a valid connection to it currently (not in DISCONNECTED state).
* Latest PING reply we received from it is not older than five seconds.
* Latest INFO reply we received from it is not older than five seconds.
* The latest INFO reply reported that the link with the master is down for no more than the time elapsed since we saw the master entering SDOWN state, plus ten times the configured `down_after_milliseconds` parameter. So for instance if a Sentinel is configured to sense the SDOWN condition after 10 seconds, and the master is down since 50 seconds, we accept a slave as a Good Slave only if the replication link was disconnected less than `50+(10*10)` seconds (two minutes and half more or less).
* It is not flagged as DEMOTE (see the section about resurrecting masters).

**Sentinel Rule #12**: A **Subjective Leader** from the point of view of a Sentinel, is the Sentinel (including itself) with the lower runid monitoring a given master, that also replied to PING less than 5 seconds ago, reported to be able to do the failover via Pub/Sub hello channel, and is not in DISCONNECTED state.

**Sentinel Rule #12**: If a master is down we ask `SENTINEL is-master-down-by-addr` to every other connected Sentinel as explained in Sentinel Rule #4. This command will also reply with the runid of the **Subjective Leader** from the point of view of the asked Sentinel. A given Sentinel believes to be the **Objective Leader** of a master if it is reported to be the subjective leader by N Sentinels (including itself), where:
* N must be equal or greater to the configured quorum for this master.
* N mast be equal or greater to the majority of the voters (`num_votres/2+1`), considering only the Sentinels that also reported the master to be down.

**Sentinel Rule #13**: A Sentinel starts the failover as a **Leader** (that is, the Sentinel actually sending the commands to reconfigure the Redis servers) if the following conditions are true at the same time:
* The master is in ODOWN condition.
* The Sentinel is configured to perform the failover with `can-failover` set to yes.
* There is at least a Good Slave from the point of view of the Sentinel.
* The Sentinel believes to be the Objective Leader.
* There is no failover in progress already detected for this master.

**Sentinel Rule #14**: A Sentinel detects a failover as an **Observer** (that is, the Sentinel just follows the failover generating the appropriate events in the log file and Pub/Sub interface, but without actively reconfiguring instances) if the following conditions are true at the same time:
* There is no failover already in progress.
* A slave instance of the monitored master turned into a master.
However the failover **will NOT be sensed as started if the slave instance turns into a master and at the same time the runid has changed** from the previous one. This means the instance turned into a master because of a restart, and is not a valid condition to consider it a slave election.

**Sentinel Rule #15**: A Sentinel starting a failover as leader does not immediately starts it. It enters a state called **wait-start**, that lasts a random amount of time between 5 seconds and 15 seconds. During this time **Sentinel Rule #14** still applies: if a valid slave promotion is detected the failover as leader is aborted and the failover as observer is detected.

End of failover
---

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

**Sentinel Rule #16** A failover is considered complete if for a leader or observer if:
* One slave was promoted to master (and the Sentinel can detect that this actually happened via INFO output), and all the additional slaves are all configured to replicate with the new slave (again, the sentinel needs to sense it using the INFO output).
* There is already a correctly promoted slave, but the configured `failover-timeout` time has already elapsed without any progress in the reconfiguration of the additional slaves. In this case a leader sends a best effort `SLAVEOF` command is sent to all the not yet configured slaves.
In both the two above conditions the promoted slave **must be reachable** (not in SDOWN state), otherwise a failover is never considered to be complete.

Leader failing during failover
---

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
case the original leader is no longer working.

**Sentinel Rule #17** A Sentinel that is an observer for a failover in progress
will turn itself into a failover leader, continuing the configuration of the
additional slaves, if all the following conditions are true:
* A failover is in progress, and this Sentinel is an observer.
* It detects to be an objective leader (so likely the previous leader is no longer reachable by other sentinels).
* At least 25% of the configured `failover-timeout` has elapsed without any progress in the observed failover process.

Promoted slave failing during failover
---

If the promoted slave has an active SDOWN condition, a Sentinel will never
sense the failover as terminated.

Additionally if there is an *extended SDOWN condition* (that is an SDOWN that
lasts for more than ten times `down-after-milliseconds` milliseconds) the
failover is aborted (this happens for leaders and observers), and the master
starts to be monitored again as usually, so that a new failover can start with
a different slave in case the master is still failing.

Note that when this happens it is possible that there are a few slaves already
configured to replicate from the (now failing) promoted slave, so when the
leader sentinel aborts a failover it sends a `SLAVEOF` command to all the
slaves already reconfigured or in the process of being reconfigured to switch
the configuration back to the original master.

**Sentinel Rule #18** A Sentinel will consider the failover process aborted, both when acting as leader and when acting as an observer, in the following conditions are true:
* A failover is in progress and a slave to promote was already selected (or in the case of the observer was already detected as master).
* The promoted slave is in **Extended SDOWN** condition (continually in SDOWN condition for at least ten times the configured `down-after-milliseconds`).

Resurrecting master
---

After the failover, at some point the old master may return back online. Starting with Redis 2.6.13 Sentinel is able to handle this condition by automatically reconfiguring the old master as a slave of the new master.

This happens in the following way:

* After the failover has started from the point of view of a Sentinel, either as a leader, or as an observer that detected the promotion of a slave, the old master is put in the list of slaves of the new master, but with a special `DEMOTE` flag (the flag can be seen in the `SENTINEL SLAVES` command output).
* Once the master is back online and it is possible to contact it again, if it still claims to be a master (from INFO output) Sentinels will send a `SLAVEOF` command trying to reconfigure it. Once the instance claims to be a slave, the `DEMOTE` flag is cleared.

There is no single Sentinel in charge of turning the old master into a slave, so the process is resistant against failing sentinels. At the same time instances with the `DEMOTE` flag set are never selected as promotable slaves.

In this specific case the `+slave` event is only generated only when the old master will report to be actually a slave again in its `INFO` output.

**Sentinel Rule #19**: Once the failover starts (either as observer or leader), the old master is added as a slave of the new master, flagged as `DEMOTE`.

**Sentinel Rule #20**: A slave instance claiming to be a master, and flagged as `DEMOTE`, is reconfigured via `SLAVEOF` every time a Sentinel receives an `INFO` output where the wrong role is detected.

**Sentinel Rule #21**: The `DEMOTE` flag is cleared as soon as an `INFO` output shows the instance to report itself as a slave.

Manual interactions
---

* TODO: Manually triggering a failover with SENTINEL FAILOVER.
* TODO: Pausing Sentinels with SENTINEL PAUSE, RESUME.

The failback process
---

* TODO: Sentinel does not perform automatic Failback.
* TODO: Document correct steps for the failback.

Clients configuration update
---

Work in progress.

TILT mode
---

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

Handling of -BUSY state
---

(Warning: Yet not implemented)

The -BUSY error is returned when a script is running for more time than the
configured script time limit. When this happens before triggering a fail over
Redis Sentinel will try to send a "SCRIPT KILL" command, that will only
succeed if the script was read-only.

Notifications via user script
---

Work in progress.

Suggested setup
---

Work in progress.

APPENDIX A - Implementation and algorithms
===

Duplicate Sentinels removal
---

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

Selection of the Slave to promote
---

If a master has multiple slaves, the slave to promote to master is selected
checking the slave priority (a new configuration option of Redis instances
that is propagated via INFO output, still not implemented), and picking the
one with lower priority value (it is an integer similar to the one of the
MX field of the DNS system).

All the slaves that appears to be disconnected from the master for a long
time are discarded.

If slaves with the same priority exist, the one with the lexicographically
smaller Run ID is selected.

Note: because currently slave priority is not implemented, the selection is
performed only discarding unreachable slaves and picking the one with the
lower Run ID.

**Sentinel Rule #22**: A Sentinel performing the failover as leader will select the slave to promote, among the existing **Good Slaves** (See rule #11), taking the one with the lower slave priority. When priority is the same the slave with lexicographically lower runid is preferred.

APPENDIX B - Get started with Sentinel in five minutes
===

If you want to try Redis Sentinel, please follow this steps:

* Clone the *unstable* branch of the Redis repository at github (it is the default branch).
* Compile it with "make".
* Start a few normal Redis instances, using the `redis-server` compiled in the *unstable* branch. One master and one slave is enough.
* Use the `redis-sentinel` executable to start three instances of Sentinel, with `redis-sentinel /path/to/config`.

To create the three configurations just create three files where you put something like that:

    port 26379
    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel down-after-milliseconds mymaster 5000
    sentinel failover-timeout mymaster 900000
    sentinel can-failover mymaster yes
    sentinel parallel-syncs mymaster 1

Note: where you see `port 26379`, use 26380 for the second Sentinel, and 26381 for the third Sentinel (any other different non colliding port will do of course). Also note that the `down-after-milliseconds` configuration option is set to just five seconds, that is a good value to play with Sentinel, but not good for production environments.

At this point you should see something like the following in every Sentinel you are running:

    [4747] 23 Jul 14:49:15.883 * +slave slave 127.0.0.1:6380 127.0.0.1 6380 @ mymaster 127.0.0.1 6379
    [4747] 23 Jul 14:49:19.645 * +sentinel sentinel 127.0.0.1:26379 127.0.0.1 26379 @ mymaster 127.0.0.1 6379
    [4747] 23 Jul 14:49:21.659 * +sentinel sentinel 127.0.0.1:26381 127.0.0.1 26381 @ mymaster 127.0.0.1 6379

    redis-cli -p 26379 sentinel masters
    1)  1) "name"
        2) "mymaster"
        3) "ip"
        4) "127.0.0.1"
        5) "port"
        6) "6379"
        7) "runid"
        8) "66215809eede5c0fdd20680cfb3dbd3bdf70a6f8"
        9) "flags"
       10) "master"
       11) "pending-commands"
       12) "0"
       13) "last-ok-ping-reply"
       14) "515"
       15) "last-ping-reply"
       16) "515"
       17) "info-refresh"
       18) "5116"
       19) "num-slaves"
       20) "1"
       21) "num-other-sentinels"
       22) "2"
       23) "quorum"
       24) "2"

To see how the failover works, just put down your slave (for instance sending `DEBUG SEGFAULT` to crash it) and see what happens.

This HOWTO is a work in progress, more information will be added in the near future.
