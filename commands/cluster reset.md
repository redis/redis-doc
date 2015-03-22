Reset a Redis Cluster node, in a less or more drastic way depending on the
reset type, that can be **hard** or **soft**. Note that this command
**does not work for masters if they hold one or more keys**, in that case
to completely reset a master node there is to call `FLUSHALL` first, and then
`CLUSTER RESET`.

Effects on the node:

1. All the other nodes in the cluster are forget.
2. All the assigned / open slots are reset, so the hash slots to nodes map is totally cleared.
3. If the node is a slave, is turned into an (empty) master. Its dataset is flushed, so at the end the node will be an empty master.
4. **Hard reset only**: a new Node ID is generated.
5. **Hard reset only**: `currentEpoch` and `configEpoch` vars are set to 0.
6. The new configuration is persisted on disk in the node cluster configuration file.

This command is mainly useful in order to re-provision a Redis Cluster node
in order to be used in the context of a new, different cluster. The command
is also extensively used by the Redis Cluster testing framework in order to
reset the state of the cluster every time a new test unit is executed.

If no reset type is specified, the default is **soft**.

@return

@simple-string-reply: `OK` if the command was successful. Otherwise an error is returned.
