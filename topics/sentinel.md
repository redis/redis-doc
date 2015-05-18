Redis Sentinel Documentation
===

Redis Sentinel is a system designed to help managing Redis instances.
It performs the following four tasks:

* **Monitoring**. Sentinel constantly checks if your master and slave
  instances are working as expected.
* **Notification**. Sentinel can notify the system administrator, or
  another computer program via an API, that something is wrong with one
of the monitored Redis instances.
* **Automatic failover**. If a master is not working as expected,
  Sentinel can start a failover process where a slave is promoted to
master, the other additional slaves are reconfigured to use the new
master, and the applications using the Redis server informed about the
current address to use when connecting.
* **Configuration provider**. Sentinel acts as a source of authority for
  clients service discovery: clients connect to Sentinels in order to
ask for the address of the current Redis master responsible for a given
service. If a failover occurs, Sentinels will report the new address.

Distributed Nature of Sentinel
---

Redis Sentinel is a distributed system. This means that normally you
will run multiple Sentinel processes across your infrastructure.  These
processes use a gossip protocol in order to understand if a master is
down and agreement protocols in order to become authorized to perform
the failover and assign a new version to the new configuration.

Distributed systems have given *safety* and *liveness* properties, in
order to use Redis Sentinel well you are supposed to understand, at
least at high level, how Sentinel works as a distributed system. This
makes Sentinel more complex but also better compared to a system using a
single process, for example:

* A cluster of Sentinels can failover a master even if some Sentinels
  are failing.
* A single Sentinel not working well, or not well connected, can't
  failover a master without authorization from other Sentinels.
* Clients can connect to any random Sentinel to fetch the configuration
  of a master.

Obtaining Sentinel
---

The current version of Sentinel is called **Sentinel 2**. It is a
rewrite of the initial Sentinel implementation using stronger and
simpler to predict algorithms (that are explained in this
documentation).

A stable release of Redis Sentinel is shipped with Redis 2.8, which is
the latest stable release of Redis.

New developments are performed in the *unstable* branch, and new
features are backported into the 2.8 branch as soon as they are
considered to be stable.

IMPORTANT: **Even if you are using Redis 2.6, you should use Sentinel
shipped with Redis 2.8**. Redis Sentinel shipped with Redis 2.6, that
is, "Sentinel 1", is deprecated and has many bugs. In general you should
migrate all your Redis and Sentinel instances to the latest Redis 2.8
ASAP to get a better and more reliable experience.

Running Sentinel
---

If you are using the `redis-sentinel` executable (or if you have a
symbolic link with that name to the `redis-server` executable) you can
run Sentinel with the following command line:

    redis-sentinel /path/to/sentinel.conf

Otherwise you can use directly the `redis-server` executable starting it
in Sentinel mode:

    redis-server /path/to/sentinel.conf --sentinel

Both ways work the same.

However **it is mandatory** to use a configuration file when running
Sentinel, as this file will be used by the system in order to save the
current state that will be reloaded in case of restarts. Sentinel will
simply refuse to start if no configuration file is given or if the
configuration file path is not writable.

Sentinels by default run **listening for connections to TCP port
26379**, so for Sentinels to work, port 26379 of your servers **must be
open** to receive connections from the IP addresses of the other
Sentinel instances.  Otherwise Sentinels can't talk and can't agree
about what to do, so failover will never be performed.

**Management Note**: As Sentinel currently modifies the configuration
file to reflect the state of the masters it manages, you should take
steps to ensure any configuration management, or package management,
system you use does not attempt to replace or manage the Sentinel
configuration file.

Configuring Sentinel
---

The Redis source distribution contains a file called `sentinel.conf`
that is a self-documented example configuration file you can use to
configure Sentinel, however a typical minimal configuration file looks
like the following:

    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel auth-pass mymaster mypass
    sentinel down-after-milliseconds mymaster 60000
    sentinel failover-timeout mymaster 180000
    sentinel parallel-syncs mymaster 1

    sentinel monitor resque 192.168.1.3 6380 4
    sentinel down-after-milliseconds resque 10000
    sentinel failover-timeout resque 180000
    sentinel parallel-syncs resque 5

You only need to specify the masters to monitor, giving each
master a unique name.  There is no need to specify slaves as they are
automatically discovered. Sentinel will update the configuration
automatically with additional information about slaves (in order to
retain the information in case of restart).  The configuration is also
rewritten every time a slave is promoted to master during a failover.

The example configuration above monitors two sets of Redis
instances, each composed of a master and an undefined number of slaves.
One set of instances is called `mymaster`, and the other `resque`.

For the sake of clarity, let's check line by line what the configuration
options mean:

The first line is used to tell Redis to monitor a master called
*mymaster*, that is at address 127.0.0.1 and port 6379, with a level of
agreement (quorum) needed to decide this master is failing of 2
sentinels. If the given number of sentinels do not agree then the
automatic failover does not start.

Note that regardless of the quorum number you specify, Sentinel *also*
requires **the vote from the majority** of the **known** Sentinels in
the system in order to start a failover and obtain a new *configuration
Epoch* to assign to the new configuration after the failover.

In the example the quorum is set to to 2, so it takes 2 sentinels to
agree a given master is not reachable, or in an error condition, for a
failover to be triggered. As you'll see in the next section deciding a
master is down is not enough to *start* a failover.

The other options are almost always in the form:

    sentinel <option_name> <master_name> <option_value>

And are used for the following purposes:

* `down-after-milliseconds` is the time in milliseconds an instance
  should not be reachable (either does not reply to our PINGs or it is
replying with an error) for a Sentinel starting to think it is down.
After this time has elapsed the Sentinel will mark an instance as
**subjectively down** (also known as `SDOWN`), that is not enough to
start the automatic failover.  However if enough instances will think
that there is a subjectively down condition, then the instance is marked
as **objectively down**. The number of sentinels that needs to agree
depends on the configured agreement for this master.

* `parallel-syncs` sets the number of slaves that can be reconfigured to
  use the new master after a failover at the same time. The lower the
number, the more time it may take for the failover process to complete.
If slaves are configured to serve old data you may not want all the
slaves to resync at the same time with the new master. While the
replication process is mostly non blocking for a slave, there is a
moment when it stops to load the bulk data from the master during a
resync. You can ensure only one slave at a time is not reachable by
setting this option to the value of 1.

Additional options are described in the rest of this document and
documented in the example `sentinel.conf` file shipped with the Redis
distribution.

All the configuration parameters can be modified at runtime using the
`SENTINEL SET` command. See the **Reconfiguring Sentinel at runtime**
section for more information.

Quorum
---

The previous section showed that every master monitored by Sentinel is
defined as having a **quorum**. This quorum specifies the number of
Sentinel processes needed to agree about the condition of the master in
order to trigger a failover.

However, after the down state is decided  **at least a majority of
Sentinels must authorize a Sentinel to initiate a failover**.

Let's try to make things a bit more clear:

* Quorum: the number of Sentinel processes that need to detect an error
  condition in order for a master to be flagged as **ODOWN**.
* The failover is triggered by the **ODOWN** state.
* Once the ODOWN state occurs, the Sentinel trying to failover is
  required to ask for authorization by wither a majority of Sentinels or
the quorum - whichever is higher.

The difference may seem subtle but is actually quite simple to
understand and use.  For example if you have 5 Sentinel instances, and
the quorum is set to 2, an ODOWN state will be triggered as soon as 2
Sentinels believe that the master is not reachable. However one of the
two Sentinels will be able to failover only if it gets authorization at
least from 3 Sentinels.

If instead the quorum is configured to 5, all the Sentinels must agree
about the master's state and the authorization from all Sentinels is
required in order to failover.

Configuration Epochs
---

Sentinels require agreement by a majority in order to start a failover
for a few important reasons:

When a Sentinel is authorized, it gets a unique **configuration epoch**
for the master it is failing over. This is a number that will be used to
version the new configuration after the failover is completed. Because a
majority agreed that a given version was assigned to a given Sentinel,
no other Sentinel will be able to use it. This means that every
configuration of every failover is versioned with a unique version.
We'll see why this is so important.

Moreover Sentinels have a rule: if a Sentinel voted for another Sentinel
for the failover of a given master, it will wait some time to try to
failover the same master again. This delay is the `failover-timeout` you
can configure in `sentinel.conf`. This means that Sentinels will not try
to failover the same master at the same time, the first to ask to be
authorized will try, if it fails another will try after some time, and
so forth.

Redis Sentinel guarantees the *liveness* property that if a majority of
Sentinels are able to talk, eventually one will be authorized to
failover if the master is down.

Redis Sentinel also guarantees the *safety* property that every Sentinel
will failover the same master using a different *configuration epoch*.

Configuration Propagation
---

Once a Sentinel is able to failover a master successfully, it will start
to broadcast the new configuration so that the other Sentinels will
update their information about a given master.

For a failover to be considered successful, it requires that the
Sentinel was able to send the `SLAVEOF NO ONE` command to the selected
slave, and that the switch to master was later observed in the `INFO`
output of the master.

At this point, even if the reconfiguration of the slaves is in progress,
the failover is considered to be successful, and all the Sentinels are
required to start reporting the new configuration.

The way a new configuration is propagated is the reason we need 
every authorized Sentinel failover to have a higher version number -
known as the "configuration epoch".

Every Sentinel continuously broadcasts it's version of the configuration
of a master using Redis Pub/Sub messages, both on the master and all the
slaves.  At the same time, all the Sentinels wait for messages to see
what is the configuration advertised by the other Sentinels.

Configurations are broadcast in the `__sentinel__:hello` Pub/Sub
channel.

Because every configuration has a different version number, the greater
version always wins over smaller versions.

For example the configuration for the master `mymaster` starts with all
the Sentinels believing the master is at 192.168.1.50:6379. This
configuration has version 1. At some time a Sentinel is authorized to do
a failover which updates the version number to 2.  If the failover is
successful, it will start to broadcast a new configuration, let's say
192.168.1.50:9000, with version 2. All the other instances will see this
configuration and will update their configuration accordingly, since the
new configuration is numerically higher than the old.

This means that Sentinel guarantees a second liveness property: a set of
Sentinels that are able to communicate will all converge to the 
configuration with the higher version number.

Basically if the net is partitioned, every partition will converge to
the higher local configuration. In the special case of no partitions,
there is a single partition and every Sentinel will agree about the
configuration.

More Details About SDOWN and ODOWN
---

As referred to earlier in this document, Redis Sentinel has two
different concepts of *being down*, one is called a *Subjectively Down*
(SDOWN) and is a down condition that is local to a given
Sentinel instance.  Another is called *Objectively Down* 
(ODOWN) and is reached when enough Sentinels (at least the number
configured as the `quorum` parameter of the monitored master) have an
SDOWN condition, and get feedback from other Sentinels using the
`SENTINEL is-master-down-by-addr` command.

From the point of view of a Sentinel an SDOWN condition is reached if we
don't receive a valid reply to PING requests for the number of seconds
specified in the configuration as `is-master-down-after-milliseconds`
parameter.

An acceptable reply to PING is one of the following:

* PING replied with +PONG.
* PING replied with -LOADING error.
* PING replied with -MASTERDOWN error.

Any other reply (or no reply) is considered non valid.

Note that SDOWN requires that no acceptable reply is received for the
whole interval configured. For instance if the interval is 30000
milliseconds (30 seconds) and we receive an acceptable ping reply every
29 seconds, the instance is considered to be working.

To switch from SDOWN to ODOWN no strong consensus algorithm is used, but
just a form of gossip: if a given Sentinel gets reports that the master
is not working from enough Sentinels in a given time range, the SDOWN is
promoted to ODOWN. If this acknowledge is later missing, the flag is
cleared.

As already explained, a more strict authorization is required in order
to really start the failover, but no failover can be triggered without
reaching the ODOWN state.

The ODOWN condition **only applies to masters**. For other kind of
instances Sentinel don't require any agreement, so the ODOWN state is
never reached for slaves and other sentinels.

Sentinels and Slaves Auto Discovery
---

While Sentinels stay connected with other Sentinels in order to
check the availability of each other and exchange
messages, you don't need to configure the other Sentinel addresses in
every Sentinel instance you run. Sentinel uses the Redis master
Pub/Sub capabilities in order to discover the other Sentinels that are
monitoring the same master.

This is obtained by sending *Hello Messages* into the channel named
`__sentinel__:hello`.

Similarly you don't need to configure what is the list of the slaves
attached to a master, as Sentinel will auto discover this list querying
Redis.

* Every Sentinel publishes a message to every monitored master and slave
  Pub/Sub channel `__sentinel__:hello`, every two seconds, announcing
its presence with ip, port, runid.
* Every Sentinel is subscribed to the Pub/Sub channel
  `__sentinel__:hello` of every master and slave, looking for unknown
sentinels. When new sentinels are detected, they are added as sentinels
of this master.
* Hello messages also include the full current configuration of the
  master. If another Sentinel has a configuration for a given master
that is older than the one received, it updates to the new configuration
immediately.
* Before adding a new sentinel to a master a Sentinel always checks if
  there is already a sentinel with the same runid or the same address
(ip and port pair). In that case all the matching sentinels are removed,
and the new added.

Consistency Under Partitions
---

Redis Sentinel configurations are eventually consistent, so every
partition will converge to the highest configuration available.  However
in a real-world system using Sentinel there are three different players:

* Redis instances.
* Sentinel instances.
* Clients.

In order to define the behavior of the system we have to consider all
three.

The following is a simple network where there are 3 nodes, each running
a Redis instance, and a Sentinel instance:

                +-------------+
                | Sentinel 1  | <--- Client A
                | Redis 1 (M) |
                +-------------+
                        |
                        |
    +-------------+     |                     +------------+
    | Sentinel 2  |-----+-- / partition / ----| Sentinel 3 | <--- Client B
    | Redis 2 (S) |                           | Redis 3 (M)|
    +-------------+                           +------------+

In this system the original state was that Redis 3 was the master, while
Redis 1 and 2 were slaves. A partition occurred isolating the old
master.  Sentinels 1 and 2 started a failover promoting Sentinel 1 as
the new master.

The Sentinel properties guarantee that Sentinel 1 and 2 now have the new
configuration for the master. However Sentinel 3 has still the old
configuration since it lives in a different partition.

We know that Sentinel 3 will get it's configuration updated when the
network partition will heal, however what happens during the partition
if there are clients partitioned with the old master?

Clients will be still able to write to Redis 3, the old master. When the
partition will rejoin, Redis 3 will be turned into a slave of Redis 1,
and all the data written during the partition will be lost.

Depending on your configuration you may want or not that this scenario
happens:

* If you are using Redis as a cache, it could be handy that Client B is
  still able to write to the old master, even if it's data will be lost.
* If you are using Redis as a store, this is not good and you need to
  configure the system in order to partially prevent this problem.

Since Redis is asynchronously replicated, there is no way to totally
prevent data loss in this scenario, however you can bound the divergence
between Redis 3 and Redis 1 using the following Redis configuration
option:

    min-slaves-to-write 1
    min-slaves-max-lag 10

With the above configuration (please see the self-commented `redis.conf`
example in the Redis distribution for more information) a Redis
instance, when acting as a master, will stop accepting writes if it
can't write to at least 1 slave. Since replication is asynchronous *not
being able to write* actually means that the slave is either
disconnected, or is not sending us asynchronous acknowledges for more
than the specified `max-lag` number of seconds.

Using this configuration the Redis 3 in the above example will become
unavailable after 10 seconds. When the partition heals, the Sentinel 3
configuration will converge to the new one, and Client B will be able to
fetch a valid configuration and continue.

Sentinel Persistent State
---

Sentinel state is persisted in the sentinel configuration file. For
example every time a new configuration is received, or created (leader
Sentinels), for a master, the configuration is persisted on disk
together with the configuration epoch. This means that it is safe to
stop and restart Sentinel processes.

Sentinel Reconfiguration of Instances Outside The Failover Procedure.
---

Even when no failover is in progress, Sentinels will always try to set
the current configuration on monitored instances. Specifically:

* Slaves (according to the current configuration) that claim to be masters, will be configured as slaves to replicate with the current master.
* Slaves connected to a wrong master, will be reconfigured to replicate with the right master.

For Sentinels to reconfigure slaves, the wrong configuration must be
observed for some time, that is greater than the period used to
broadcast new configurations.

This prevents that Sentinels with a stale configuration (for example
because they just rejoined from a partition) will try to change the
slaves configuration before receiving an update.

Also note how the semantics of always trying to impose the current
configuration makes the failover more resistant to partitions:

* Masters failed over are reconfigured as slaves when they return
  available.
* Slaves partitioned away during a partition are reconfigured once
  reachable.

Slave Selection and Priority
---

When a Sentinel instance is ready to perform a failover, since the
master is in `ODOWN` state and the Sentinel received the authorization
to failover from the majority of the Sentinel instances known, a
suitable slave needs to be selected.

The slave selection process evaluates the following information about
slaves:

1. Disconnection time from the master.
2. Slave priority.
3. Replication offset processed.
4. Run ID.

A slave that is found to be disconnected from the master for more than
ten times the configured master timeout (down-after-milliseconds
option), plus the time the master is also not available from the point
of view of the Sentinel doing the failover, is considered to be not
suitable for the failover and is skipped.

In more rigorous terms, a slave whose the `INFO` output suggests to be
disconnected from the master for more than:

    (down-after-milliseconds * 10) + milliseconds_since_master_is_in_SDOWN_state

Is considered to be unreliable and is disregarded entirely.

The slave selection only considers the slaves that passed the above
test, and sorts it based on the above criteria, in the following order.

1. The slaves are sorted by `slave-priority` as configured in the
   `redis.conf` file of the Redis instance. A lower priority will be
preferred.
2. If the priority is the same, the replication offset processed by the
   slave is checked, and the slave that received more data from the
master is selected.
3. If multiple slaves have the same priority and processed the same data
   from the master, a further check is performed, selecting the slave
with the lexicographically smaller run ID. Having a lower run ID is not
a real advantage for a slave, but is useful in order to make the process
of slave selection more deterministic, instead of resorting to select a
random slave.

Redis masters (that may be turned into slaves after a failover), and
slaves, all must be configured with a `slave-priority` if there are
machines to be strongly preferred. Otherwise all the instances can run
with the default run ID (which is the suggested setup, since it is far
more interesting to select the slave by replication offset).

A Redis instance can be configured with a special `slave-priority` of
zero in order to be **never selected** by Sentinels as the new master.
However a slave configured in this way will still be reconfigured by
Sentinels in order to replicate with the new master after a failover,
the only difference is that it will never become a master itself.

Sentinel and Redis Authentication
---

When the master is configured to require a password from clients, as a
security measure, slaves need to also be aware of this password in order
to authenticate with the master and create the master-slave connection
used for the asynchronous replication protocol.

This is achieved using the following configuration directives:

* `requirepass` in the master, in order to set the authentication
  password, and to make sure the instance will not process requests for
non authenticated clients.
* `masterauth` in the slaves in order for the slaves to authenticate
  with the master in order to correctly replicate data from it.

When Sentinel is used, there is not a single master, since after a
failover slaves may play the role of masters, and old masters can be
reconfigured in order to act as slaves, so what you want to do is to set
the above directives in all your instances, both masters and slaves.

This is also usually a logically sane setup since you don't want to
protect data only in the master, having the same data accessible in the
slaves.

However, in the uncommon case where you need a slave that is accessible
without authentication, you can still do it by setting up a slave
priority of zero (that will not allow the slave to be promoted to
master), and configuring only the `masterauth` directive for this slave,
without the `requirepass` directive, so that data will be readable by
unauthenticated clients.

Sentinel API
===

By default Sentinel runs using TCP port 26379 (note that 6379 is the
normal Redis port). Sentinels accept commands using the Redis protocol,
so you can use `redis-cli` or any other unmodified Redis client in order
to talk with Sentinel.

There are two ways to talk with Sentinel: it is possible to directly
query it to check what is the state of the monitored Redis instances
from it's point of view, to see what other Sentinels it knows, and so
forth.

An alternative is to use Pub/Sub to receive *push style* notifications
from Sentinels, every time some event happens, like a failover, or an
instance entering an error condition, and so forth.

Sentinel Commands
---

The following is a list of accepted commands:

* **PING** This command simply returns PONG.
* **SENTINEL masters** Show a list of monitored masters and their state.
* **SENTINEL master `<master name>`** Show the state and info of the
  specified master.
* **SENTINEL slaves `<master name>`** Show a list of slaves for this
  master, and their state.
* **SENTINEL get-master-addr-by-name `<master name>`** Return the ip and
  port number of the master with that name. If a failover is in progress
or terminated successfully for this master it returns the address and
port of the promoted slave.
* **SENTINEL reset `<pattern>`** This command will reset all the masters
  with matching name. The pattern argument is a glob-style pattern. The
reset process clears any previous state in a master (including a
failover in progress), and removes every slave and sentinel already
discovered and associated with the master.
* **SENTINEL failover `<master name>`** Force a failover as if the
  master was not reachable, and without asking for agreement to other
Sentinels (however a new version of the configuration will be published
so that the other Sentinels will update their configurations).

Reconfiguring Sentinel at Runtime
---

Starting with Redis version 2.8.4, Sentinel provides an API in order to
add, remove, or change the configuration of a given master. Note that if
you have multiple sentinels you should apply the changes to all to your
instances for Redis Sentinel to work properly. This means that changing
the configuration of a single Sentinel does not automatically propagates
the changes to the other Sentinels in the network.

The following is a list of `SENTINEL` sub commands used in order to
update the configuration of a Sentinel instance.

* **SENTINEL MONITOR `<name>` `<IP>` `<port>` `<quorum>`** This command
  tells the Sentinel to start monitoring a new master with the specified
name, ip, port, and quorum. It is identical to the `sentinel monitor`
configuration directive in `sentinel.conf` configuration file, with the
difference that you can't use an hostname in as `ip`, but you need to
provide an IPv4 or IPv6 address.
* **SENTINEL REMOVE `<name>`** is used in order to remove the specified
  master: the master will no longer be monitored, and will totally be
removed from the internal state of the Sentinel, so it will no longer
listed by `SENTINEL masters` and so forth. **Note**: Currently this
event is *not* propogated to other Sentinels managing the given master,
this their information on other known sentinels will be 'stale'.
* **SENTINEL SET `<name>` `<option>` `<value>`** The SET command is very
  similar to the `CONFIG SET` command of Redis, and is used in order to
change configuration parameters of a specific master. Multiple option /
value pairs can be specified (or none at all). All the configuration
parameters that can be configured via `sentinel.conf` are also
configurable using the SET command.

The following is an example of `SENTINEL SET` command in order to modify
the `down-after-milliseconds` configuration of a master called
`objects-cache`:

    SENTINEL SET objects-cache-master down-after-milliseconds 1000

As already stated, `SENTINEL SET` can be used to set all the
configuration parameters that are settable in the startup configuration
file. Moreover it is possible to change just the master quorum
configuration without removing and re-adding the master with `SENTINEL
REMOVE` followed by `SENTINEL MONITOR`, but simply using:

    SENTINEL SET objects-cache-master quorum 5

Note that there is no equivalent GET command since `SENTINEL MASTER`
provides all the configuration parameters in a simple to parse format
(as a field/value pairs array).

The following is an example of completely using the API to add a master
to the sentinel, including the setting of the master's password.

    SENTINEL MONITOR objects-cache-master 192.168.1.101 2
    SENTINEL SET objects-cache-master auth-pass mysecretauthstring


Adding or Removing Sentinels
---

Adding a new Sentinel to your deployment is a simple process because of
the auto-discover mechanism implemented by Sentinel. All you need to do
is to start the new Sentinel configured to monitor the currently active
master.  Within 10 seconds the Sentinel will acquire the list of other
Sentinels and the set of slaves attached to the master.

If you need to add multiple Sentinels at once, it is recommended to add
them individually, waiting for all the other Sentinels to discovery the
new one before adding the next. This is useful to still guarantee that
majority can be achieved only in one side of a partition, in the chance
failures should happen in the process of adding new Sentinels.

This can be easily achieved by adding every new Sentinel with a 30
seconds delay, and during absence of network partitions.

At the end of the process it is possible to use the command `SENTINEL
MASTER mastername` on each Sentinel in order to check if all the
Sentinels agree about the total number of Sentinels monitoring the
master.

Removing a Sentinel is a bit more complex as Sentinels never forget each
other even if they are not reachable for a long time. This is due to
Sentinel not knowing if we *should* be dynamically changing the majority
needed to authorize a failover.

In order to remove a sentinel follow this process: 

1. Stop the Sentinel process of the Sentinel you want to remove.
2. Send a `SENTINEL RESET <name>` command to all the other Sentinel
   instances, one after the other, waiting at least 30
seconds between instances.
3. Check that all the Sentinels agree about the number of Sentinels
   currently active, by inspecting the output of `SENTINEL MASTER
mastername` on each Sentinel.

Removing The Old Master Or Unreachable Slaves.
---

Sentinels never forget about slaves of a given master, even when they
are unreachable for a long time. This is useful, because Sentinels
should be able to correctly reconfigure a returning slave after a
network partition or a failure event.

Moreover, after a failover, the failed over master is virtually added as
a slave of the new master, this way it will be reconfigured to replicate
with the new master as soon as it will be available again.

However sometimes you want to remove a slave (that may be the old
master) forever from the list of slaves monitored by Sentinels.

In order to do this, you need to send a `SENTINEL RESET <mastername>`
command to all the Sentinels following the same proces as for removing
sentinel. A sentinel reset will cause sentinel to refresh the list of
slaves within only adding the ones listed as correctly replicating from
the current master `INFO` output.

Pub/Sub Messages
---

A client can use a Sentinel as a sub-only Redis compatible Pub/Sub
server in order to `SUBSCRIBE` or `PSUBSCRIBE` to channels and get
notified about specific events.

The channel name is the same as the name of the event. For instance the
channel named `+sdown` will receive all the notifications related to
instances entering an `SDOWN` condition.

To get all the messages subscribe with `PSUBSCRIBE *`.

The following is a list of channels and message formats you can receive
using this API. The first word is the channel / event name, the rest is
the format of the data.

Note: where *instance details* is specified it means that the following
arguments are provided to identify the target instance:

    <instance-type> <name> <ip> <port> @ <master-name> <master-ip> <master-port>

The part identifying the master (from the @ argument to the end) is
optional and is only specified if the instance is not a master itself.

* **+reset-master** `<instance details>` -- The master was reset.
* **+slave** `<instance details>` -- A new slave was detected and
  attached.
* **+failover-state-reconf-slaves** `<instance details>` -- Failover
  state changed to `reconf-slaves` state.
* **+failover-detected** `<instance details>` -- A failover started by
  another Sentinel or any other external entity was detected (An
attached slave turned into a master).
* **+slave-reconf-sent** `<instance details>` -- The leader sentinel
  sent the `SLAVEOF` command to this instance in order to reconfigure it
for the new slave.
* **+slave-reconf-inprog** `<instance details>` -- The slave being
  reconfigured showed to be a slave of the new master ip:port pair, but
the synchronization process is not yet complete.
* **+slave-reconf-done** `<instance details>` -- The slave is now
  synchronized with the new master.
* **-dup-sentinel** `<instance details>` -- One or more sentinels for
  the specified master were removed as duplicated (this happens for
instance when a Sentinel instance is restarted).
* **+sentinel** `<instance details>` -- A new sentinel for this master
  was detected and attached.
* **+sdown** `<instance details>` -- The specified instance is now in
  Subjectively Down state.
* **-sdown** `<instance details>` -- The specified instance is no longer
  in Subjectively Down state.
* **+odown** `<instance details>` -- The specified instance is now in
  Objectively Down state.
* **-odown** `<instance details>` -- The specified instance is no longer
  in Objectively Down state.
* **+new-epoch** `<instance details>` -- The current epoch was updated.
* **+try-failover** `<instance details>` -- New failover in progress,
  waiting to be elected by the majority.
* **+elected-leader** `<instance details>` -- Won the election for the
  specified epoch, can do the failover.
* **+failover-state-select-slave** `<instance details>` -- New failover
  state is `select-slave`: we are trying to find a suitable slave for
promotion.
* **no-good-slave** `<instance details>` -- There is no good slave to
  promote. Currently we'll try after some time, but probably this will
change and the state machine will abort the failover at all in this
case.
* **selected-slave** `<instance details>` -- We found the specified good
  slave to promote.
* **failover-state-send-slaveof-noone** `<instance details>` -- We are
  trying to reconfigure the promoted slave as master, waiting for it to
switch.
* **failover-end-for-timeout** `<instance details>` -- The failover
  terminated for timeout, slaves will eventually be configured to
replicate with the new master anyway.
* **failover-end** `<instance details>` -- The failover terminated with
  success. All the slaves appears to be reconfigured to replicate with
the new master.
* **switch-master** `<master name> <oldip> <oldport> <newip> <newport>`
  -- The master new IP and address is the specified one after a
configuration change. This is **the message most external users are
interested in**.
* **+tilt** -- Tilt mode entered.
* **-tilt** -- Tilt mode exited.

TILT Mode
---

In order to understand if an instance is available sentinel remembers
the time of the latest successful reply to the PING command and 
compares it with the current time to understand how long it has been
since it received a valid response. Thus, Redis Sentinel is heavily
dependent on the computer time. 

Therefore if the computer time changes in an unexpected way, which could
happen if the computer is very busy or the process blocked for some
reason, Sentinel may start to behave in an unexpected way.

The TILT mode is a special "protective" state a Sentinel can enter
when something odd is detected which might lower the reliability of the
system. The Sentinel timer interrupt is normally called 10 times per
second, so we expect more or less 100 milliseconds will elapse
between two calls to the timer interrupt.

What a Sentinel does is to register the previous time the timer
interrupt was called, and compare it with the current call: if the time
difference is negative or unexpectedly large (2 seconds or more) the
TILT mode is entered (or if it was already entered the exit from the
TILT mode postponed).

When in TILT mode the Sentinel will continue to monitor everything, but:

* It stops acting at all.
* It starts to reply negatively to `SENTINEL is-master-down-by-addr`
  requests as the ability to detect a failure is no longer trusted.

If everything appears to be normal for 30 seconds, the TILT mode is
automatically ended.

Handling of -BUSY State
---

(Warning: Yet not implemented)

The -BUSY error is returned when a script is running for more time than
the configured script time limit. When this happens before triggering a
fail over Redis Sentinel will try to send a "SCRIPT KILL" command, that
will only succeed if the script was read-only.

Sentinel Clients Implementation
---

Sentinel requires explicit client support, unless the system is
configured to execute a script that performs a transparent redirection
of all the requests to the new master instance (virtual IP or other
similar systems). The topic of client libraries implementation is
covered in the document [Sentinel clients
guidelines](/topics/sentinel-clients).
