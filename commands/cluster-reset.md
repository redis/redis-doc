Reset a Redis Cluster node, in a more or less drastic way depending on the reset type, which can be _hard_ or _soft_.
Note that this command **does not work for masters if they hold any keys**.
To completely reset a master node, keys must be removed first by calling `FLUSHALL` first,
and then `CLUSTER RESET`.

Effects on the node:

1. All the other nodes in the cluster are forgotten.
2. All the assigned / open slots are reset, so the slots-to-nodes mapping is totally cleared.
3. If the node is a replica it is turned into an (empty) master. Its dataset is flushed, so at the end, the node will be an empty master.
4. **Hard reset only**: a new Node ID is generated.
5. **Hard reset only**: `currentEpoch` and `configEpoch` vars are set to 0.
6. The new configuration is persisted on disk in the node cluster configuration file.

This command is mainly useful to re-provision a Redis Cluster node to be used in the context of a new, different cluster.
The command is also extensively used by the Redis Cluster testing framework to
reset the state of the cluster every time a new test unit is executed.

If no reset type is specified, the default is _soft_.

@return

@simple-string-reply: `OK` if the command was successful. Otherwise, an error is returned.
