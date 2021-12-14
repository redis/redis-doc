The command behavior is the following:

* If there are any replicas lagging behind in replication:
  * Pause clients attempting to write by performing a `CLIENT PAUSE` with the `WRITE` option.
  * Wait up to the configured `shutdown-timeout` (default 10 seconds) for replicas to catch up the replication offset.
* Stop all the clients.
* Perform a blocking SAVE if at least one **save point** is configured.
* Flush the Append Only File if AOF is enabled.
* Quit the server.

If persistence is enabled this commands makes sure that Redis is switched off
without the lost of any data.

Note: A Redis instance that is configured for not persisting on disk (no AOF
configured, nor "save" directive) will not dump the RDB file on `SHUTDOWN`, as
usually you don't want Redis instances used only for caching to block on when
shutting down.

Also note: If Redis receives one of the signals SIGTERM and SIGINT, the same shutdown sequence is performed.
See also [Signal Handling](/topics/signals).

## Modifiers

It is possible to specify optional modifiers to alter the behavior of the command.
Specifically:

* **SAVE** will force a DB saving operation even if no save points are configured.
* **NOSAVE** will prevent a DB saving operation even if one or more save points are configured.
* **NOW** skips waiting for lagging replicas, i.e. it bypasses the first step in the shutdown sequence.
* **FORCE** ingores any errors that would normally prevent the server from exiting.

## Conditions where a SHUTDOWN fails

When a save point is configured or the **SAVE** modifier is specified, the shutdown may fail if the RDB file can't be saved.
Then, the server continues to run in order to ensure no data loss.
This may be bypassed using the **FORCE** modifier, casuing the server to exit anyway.

When the Append Only File is enabled the shutdown may fail because the
system is in a state that does not allow to safely immediately persist
on disk.

Normally if there is an AOF child process performing an AOF rewrite, Redis
will simply kill it and exit. However there are two conditions where it is
unsafe to do so, and the **SHUTDOWN** command will be refused with an error
instead. This happens when:

* The user just turned on AOF, and the server triggered the first AOF rewrite in order to create the initial AOF file. In this context, stopping will result in losing the dataset at all: once restarted, the server will potentially have AOF enabled without having any AOF file at all.
* A replica with AOF enabled, reconnected with its master, performed a full resynchronization, and restarted the AOF file, triggering the initial AOF creation process. In this case not completing the AOF rewrite is dangerous because the latest dataset received from the master would be lost. The new master can actually be even a different instance (if the **REPLICAOF** or **SLAVEOF** command was used in order to reconfigure the replica), so it is important to finish the AOF rewrite and start with the correct data set representing the data set in memory when the server was terminated.
* The **FORCE** modifier is *not* specified. If **FORCE** is specified, the server exits anyway.

There are conditions when we want just to terminate a Redis instance ASAP, regardless of what its content is.
In such a case, the right command to send is **SHUTDOWN NOW NOSAVE FORCE**.
In versions before 7.0, when the **NOW** and **FORCE** flags were not available, the right combination of commands was to send a **CONFIG appendonly no** followed by a **SHUTDOWN NOSAVE**.
The first command will turn off the AOF if needed, and will terminate the AOF rewriting child if there is one active.
The second command will not have any problem to execute since the AOF is no longer enabled.

## Minimize the risk of data loss

Since Redis 7.0, the server waits for lagging replicas up to a configurable `shutdown-timeout`, by default 10 seconds, before shutting down.
This provides a best effort minimizing the risk of data loss in a situation where no save points are configured and AOF is disabled.
Before version 7.0, shutting down a heavily loaded master node in a diskless setup is more likely to result in data loss.
To minimize the risk of data loss in such setups, it's adviced to trigger a manual `FAILOVER` (or `CLUSTER FAILOVER`) to demote the master to a replica and promote one of the replicas to new master, before shutting down a master node.

@return

@simple-string-reply on error.
On success nothing is returned since the server quits and the connection is
closed.

@history

* `>= 7.0`: NOW and FORCE modifiers added.
  Waiting for lagging replicas before exiting added.
