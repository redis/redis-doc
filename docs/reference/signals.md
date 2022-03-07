---
title: "Redis signal handling"
linkTitle: "Signal handling"
weight: 1
description: How Redis handles common Unix signals
aliases:
    - /topics/signals
---

This document provides information about how Redis reacts to different POSIX signals such as `SIGTERM` and `SIGSEGV`.

The information in this document **only applies to Redis version 2.6 or greater**.

## SIGTERM and SIGINT

The `SIGTERM` and `SIGINT` signals tell Redis to shut down gracefully. When the server receives this signal,
it does not immediately exit. Instead, it schedules
a shutdown similar to the one performed by the `SHUTDOWN` command. The scheduled shutdown starts as soon as possible, specifically as long as the
current command in execution terminates (if any), with a possible additional
delay of 0.1 seconds or less.

If the server is blocked by a long-running Lua script,
kill the script with `SCRIPT KILL` if possible. The scheduled shutdown will
run just after the script is killed or terminates spontaneously.

This shutdown process includes the following actions:

* If there are any replicas lagging behind in replication:
  * Pause clients attempting to write with `CLIENT PAUSE` and the `WRITE` option.
  * Wait up to the configured `shutdown-timeout` (default 10 seconds) for replicas to catch up with the master's replication offset.
* If a background child is saving the RDB file or performing an AOF rewrite, the child process is killed.
* If the AOF is active, Redis calls the `fsync` system call on the AOF file descriptor to flush the buffers on disk.
* If Redis is configured to persist on disk using RDB files, a synchronous (blocking) save is performed. Since the save is synchronous, it doesn't use any additional memory.
* If the server is daemonized, the PID file is removed.
* If the Unix domain socket is enabled, it gets removed.
* The server exits with an exit code of zero.

IF the RDB file can't be saved, the shutdown fails, and the server continues to run in order to ensure no data loss.
Likewise, if the user just turned on AOF, and the server triggered the first AOF rewrite in order to create the initial AOF file but this file can't be saved, the shutdown fails and the server continues to run.
Since Redis 2.6.11, no further attempt to shut down will be made unless a new `SIGTERM` is received or the `SHUTDOWN` command is issued.

Since Redis 7.0, the server waits for lagging replicas up to a configurable `shutdown-timeout`, 10 seconds by default, before shutting down.
This provides a best effort to minimize the risk of data loss in a situation where no save points are configured and AOF is deactivated.
Before version 7.0, shutting down a heavily loaded master node in a diskless setup was more likely to result in data loss.
To minimize the risk of data loss in such setups, trigger a manual `FAILOVER` (or `CLUSTER FAILOVER`) to demote the master to a replica and promote one of the replicas to a new master before shutting down a master node.

## SIGSEGV, SIGBUS, SIGFPE and SIGILL

The following signals are handled as a Redis crash:

* SIGSEGV
* SIGBUS
* SIGFPE
* SIGILL

Once one of these signals is trapped, Redis stops any current operation and performs the following actions:

* Adds a bug report to the log file. This includes a stack trace, dump of registers, and information about the state of clients.
* Since Redis 2.8, a fast memory test is performed as a first check of the reliability of the crashing system.
* If the server was daemonized, the PID file is removed.
* Finally the server unregisters its own signal handler for the received signal and resends the same signal to itself to make sure that the default action is performed, such as dumping the core on the file system.

## What happens when a child process gets killed

When the child performing the Append Only File rewrite gets killed by a signal,
Redis handles this as an error and discards the (probably partial or corrupted)
AOF file. It will attempt the rewrite again later.

When the child performing an RDB save is killed, Redis handles the
condition as a more severe error. While the failure of an
AOF file rewrite can cause AOF file enlargement, failed RDB file
creation reduces durability.

As a result of the child producing the RDB file being killed by a signal,
or when the child exits with an error (non zero exit code), Redis enters
a special error condition where no further write command is accepted.

* Redis will continue to reply to read commands.
* Redis will reply to all write commands with a `MISCONFIG` error.

This error condition will persist until it becomes possible to create an RDB file successfully.

## Kill the RDB file without errors

Sometimes the user may want to kill the RDB-saving child process without
generating an error. Since Redis version 2.6.10, this can be done using the signal `SIGUSR1`. This signal is handled in a special way:
it kills the child process like any other signal, but the parent process will
not detect this as a critical error and will continue to serve write
requests.
