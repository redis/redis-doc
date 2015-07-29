The command is used in order to remove the node, specified via its node ID,
from the set of nodes known by the Redis Cluster node receiving the command.
In other words the specified node is removed from the *nodes table* of the
node receiving the command.

However the command cannot simply drop the node from its internal configuration,
it also implements a ban-list, not allowing the same node to be added again
as a side effect of processing the *gossip section* of the heartbeat packets
received from other nodes.

## Details on the command behavior

For example, let's assume we have four nodes, A, B, C and D. In order to
end with just a three nodes cluster A, B, C we may follow these steps:

1. Reshard all the hash slots from D to nodes A, B, C.
2. D is now empty, but still listed in the nodes table of A, B and C.
3. We contact A, and send `CLUSTER FORGET D`.
4. B sends A a heartbeat packet, where node D is listed.
5. A does no longer known node D (see step 3), so it starts an handshake with D.
6. D ends re-added in the nodes table of A.

As you can see in this way removing a node is fragile, we need to send
`CLUSTER FORGET` commands to all the nodes ASAP hoping there are no
gossip sections processing in the meantime. Because of this problem the
command implements a ban-list with an expire time for each entry.

So what the command really does is:

1. The specified node gets removed from the nodes table.
2. The node ID of the removed node gets added to the ban-list, for 1 minute.
3. The node will skip all the node IDs listed in the ban-list when processing gossip sections received in heartbeat packets from other nodes.

This way we have a 60 second window to inform all the nodes in the cluster that
we want to remove a node.

## Special conditions not allowing the command execution

The command does not succeed and returns an error in the following cases:

1. The specified node ID is not found in the nodes table.
2. The node receiving the command is a slave, and the specified node ID identifies its current master.
3. The node ID identifies the same node we are sending the command to.

@return

@simple-string-reply: `OK` if the command was executed successfully, otherwise an error is returned.
