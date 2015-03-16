This command asks a Redis Cluster node to set the hash slots specified as arguments as *not associated* in the node receiving the command. A node associated, or
*unbound* hash slot, means that the node has no idea who is the master currently
serving the hash slot. Moreover hash slots which are not associated will be
associated as soon as we receive an heartbeat packet from some node claiming to
be the owner of the hash slot (moreover, the hash slot will be re-associated if
the node will receive an heartbeat or update message with a configuration
epoch greater than the one of the node currently bound to the hash slot).

However note that:

1. The command only works if all the specified slots are already associated with some node.
2. The command fails if the same slot is specified multiple times.
3. As a side effect of the command execution, the node may go into *down* state because not all hash slots are covered.

## Example

For example the following command assigns slots 1 2 3 to the node receiving
the command:

    > CLUSTER DELSLOTS 5000 5001
    OK

## Usage in Redis Cluster

This command only works in cluster mode and may be useful for debugging
and in order to manually orchestrate a cluster configuration when a new
cluster is created. It is currently not used by `redis-trib`, and mainly
exists for API completeness.

@return

@simple-string-reply: `OK` if the command was successful. Otheriwse an error is returned.
