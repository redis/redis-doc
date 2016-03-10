Redis latency monitoring framework
===

Redis is often used in the context of demanding use cases, where it
serves a big amount of queries per second per instance, and at the same
time, there are very strict latency requirements both for the average response
time and for the worst case latency.

While Redis is an in memory system, it deals with the operating system in
different ways, for example, in the context of persisting to disk.
Moreover Redis implements a rich set of commands. Certain commands
are fast and run in constant or logarithmic time, other commands are slower
O(N) commands, that can cause latency spikes.

Finally Redis is single threaded: this is usually an advantage
from the point of view of the amount of work it can perform per core, and in
the latency figures it is able to provide, but at the same time it poses
a challenge from the point of view of latency, since the single
thread must be able to perform certain tasks incrementally, like for
example keys expiration, in a way that does not impact the other clients
that are served.

For all these reasons, Redis 2.8.13 introduced a new feature called
**Latency Monitoring**, that helps the user to check and troubleshoot possible
latency problems. Latency monitoring is composed of the following conceptual
parts:

* Latency hooks that sample different latency sensitive code paths.
* Time series recording of latency spikes split by different event.
* Reporting engine to fetch raw data from the time series.
* Analysis engine to provide human readable reports and hints according to the measurements.

The remaining part of this document covers the latency monitoring subsystem
details, however for more information about the general topic of Redis
and latency, please read the [Redis latency problems troubleshooting](/topics/latency) page in this documentation.

Events and time series
---

Different monitored code paths have different names, and are called *events*.
For example `command` is an event measuring latency spikes of possibly slow
commands executions, while `fast-command` is the event name for the monitoring
of the O(1) and O(log N) commands. Other events are less generic, and monitor
a very specific operation performed by Redis. For example the `fork` event
only monitors the time taken by Redis to execute the `fork(2)` system call.

A latency spike is an event that runs in more time than the configured latency
threshold. There is a separated time series associated with every monitored
event. This is how the time series work:

* Every time a latency spike happens, it is logged in the appropriate time series.
* Every time series is composed of 160 elements.
* Each element is a pair: an unix timestamp of the time the latency spike was measured, and the number of milliseconds the event took to executed.
* Latency spikes for the same event happening in the same second are merged (by taking the maximum latency), so even if continuous latency spikes are measured for a given event, for example because the user set a very low threshold, at least 180 seconds of history are available.
* For every element the all-time maximum latency is recorded.

How to enable latency monitoring
---

What is high latency for an use case, is not high latency for another. There are applications where all the queries must be served in less than 1 millisecond and applications where from time to time a small percentage of clients experiencing a 2 seconds latency is acceptable.

So the first step to enable the latency monitor is to set a **latency threshold** in milliseconds. Only events that will take more than the specified threshold will be logged as latency spikes. The user should set the threshold according to its needs. For example if for the requirements of the application based on Redis the maximum acceptable latency is 100 milliseconds, the threshold should be set to such a value in order to log all the events blocking the server for a time equal or greater to 100 milliseconds.

The latency monitor can easily be enabled at runtime in a production server
with the following command:

    CONFIG SET latency-monitor-threshold 100

By default monitoring is disabled (threshold set to 0), even if the actual cost of latency monitoring is near zero. However while the memory requirements of latency monitoring are very small, there is no good reason to raise the baseline memory usage of a Redis instance that is working well.

Information reporting with the LATENCY command
---

The user interface to the latency monitoring subsystem is the `LATENCY` command.
Like many other Redis commands, `LATENCY` accept subcommands that modify the
behavior of the command. The next sections document each subcommand.

LATENCY LATEST
---

The `LATENCY LATEST` command reports the latest latency events logged. Each event has the following fields:

* Event name.
* Unix timestamp of the latest latency spike for the event.
* Latest event latency in millisecond.
* All time maximum latency for this event.

All time does not really mean the maximum latency since the Redis instance was
started, because it is possible to reset events data using `LATENCY RESET` as we'll see later.

The following is an example output:

```
127.0.0.1:6379> debug sleep 1
OK
(1.00s)
127.0.0.1:6379> debug sleep .25
OK
127.0.0.1:6379> latency latest
1) 1) "command"
   2) (integer) 1405067976
   3) (integer) 251
   4) (integer) 1001
```

LATENCY HISTORY `event-name`
---

The `LATENCY HISTORY` command is useful in order to fetch raw data from the
event time series, as timestamp-latency pairs. The command will return up
to 160 elements for a given event. An application may want to fetch raw data
in order to perform monitoring, display graphs, and so forth.

Example output:

```
127.0.0.1:6379> latency history command
1) 1) (integer) 1405067822
   2) (integer) 251
2) 1) (integer) 1405067941
   2) (integer) 1001
```

LATENCY RESET [`event-name` ... `event-name`]
---

The `LATENCY RESET` command, if called without arguments, resets all the
events, discarding the currently logged latency spike events, and resetting
the maximum event time register.

It is possible to reset only specific events by providing the event names
as arguments. The command returns the number of events time series that were
reset during the command execution.

LATENCY GRAPH `event-name`
---

Produces an ASCII-art style graph for the specified event:

```
127.0.0.1:6379> latency reset command
(integer) 0
127.0.0.1:6379> debug sleep .1
OK
127.0.0.1:6379> debug sleep .2
OK
127.0.0.1:6379> debug sleep .3
OK
127.0.0.1:6379> debug sleep .5
OK
127.0.0.1:6379> debug sleep .4
OK
127.0.0.1:6379> latency graph command
command - high 500 ms, low 101 ms (all time high 500 ms)
--------------------------------------------------------------------------------
   #_
  _||
 _|||
_||||

11186
542ss
sss
```

The vertical labels under each graph column represent the amount of seconds,
minutes, hours or days ago the event happened. For example "15s" means that the
first graphed event happened 15 seconds ago.

The graph is normalized in the min-max scale so that the zero (the underscore
in the lower row) is the minimum, and a # in the higher row is the maximum.

The graph subcommand is useful in order to get a quick idea about the trend
of a given latency event without using additional tooling, and without the
need to interpret raw data as provided by `LATENCY HISTORY`.

LATENCY DOCTOR
---

The `LATENCY DOCTOR` command is the most powerful analysis tool in the latency
monitoring, and is able to provide additional statistical data like the average
period between latency spikes, the median deviation, and an human readable
analysis of the event. For certain events, like `fork`, additional information
is provided, like the rate at which the system forks processes.

This is the output you should post in the Redis mailing list if you are
looking for help about Latency related issues.

Example output:

    127.0.0.1:6379> latency doctor

    Dave, I have observed latency spikes in this Redis instance.
    You don't mind talking about it, do you Dave?

    1. command: 5 latency spikes (average 300ms, mean deviation 120ms,
       period 73.40 sec). Worst all time event 500ms.

    I have a few advices for you:

    - Your current Slow Log configuration only logs events that are
      slower than your configured latency monitor threshold. Please
      use 'CONFIG SET slowlog-log-slower-than 1000'.
    - Check your Slow Log to understand what are the commands you are
      running which are too slow to execute. Please check
      http://redis.io/commands/slowlog for more information.
    - Deleting, expiring or evicting (because of maxmemory policy)
      large objects is a blocking operation. If you have very large
      objects that are often deleted, expired, or evicted, try to
      fragment those objects into multiple smaller objects.

The doctor has erratic psychological behaviors, so we recommend interacting with
it carefully.
