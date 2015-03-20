This command, that can only be send to a Redis Cluster slave node, forces
the slave to start a manual failover of its master instance.

A manual failover is a special kind of failover that is usually executed when
there are no actual failures, but we wish to swap the current master with one
of its slaves (which is the node we send the command to), in a safe way,
without any window for data loss. It works in the following way:

1. The slave tells the master to stop porcessing queries from clients.
2. The master replies to the slave with the current *replication offset*.
3. The slave waits for the replication offset to match on its side, to make sure it processed all the data from the slave before to continue.
4. The slave starts a failover, obtains a new configuration epoch from the majority of the masters, and broadcast the new configuration.
5. The old master receives the configuration update: unblocks its clients and start replying with redirection messages so that they'll continue the chat with the new master.

This way clients are moved away from the old master to the new master
atomically and only when the slave that is turning in the new master
processed all the replication stream from the old master.

If the **FORCE** option is given, the slave does not perform any handshake
with the master, that may be not reachable, but instead just starts a
failover ASAP starting from point 4. This is useful when we want to start
a manual failover while the master is no longer reachable.

Note that a manual failover is different than a normal failover triggered
by the Redis Cluster failure detection algorithm in a few ways:

1. The data validity of the slave is not checked. Even if the slave has not recently updated data, it will failover anyway if we use `CLUSTER FAILOVER FORCE`.
2. There is no random delay before the failover starts.

Note that currently a manual failover is not able to promote a slave into
master if it can't receive votes from the majority of masters in order to
create a new unique configuration epoch number.

`CLUSTER FAILOVER` does not execute a failover synchronously, it only
*schedules* a manual failover, bypassing the failure detection stage, so to
check if the failover actually happened, `CLUSTER NODES` or other means
should be used to check the state change.

@return

@simple-string-reply: `OK` if the command was accepted and a manual failover is going to be attempted. An error if the operation cannot be executed, for example if we are talking with a node which is already a master.
