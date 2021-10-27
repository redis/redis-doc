The `CLUSTER DELSLOTSRANGE` command is similar to the `CLUSTER DELSLOTS` command in that they both remove hash slots from the node. The difference is that `DELSLOTS` takes a list of hash slots to remove from the node, while `DELSLOTSRANGE` takes a list of slot ranges (specified by start and end slots) to remove to the node.

## Example

The following command removes the association for slots 5000 and
5200 from the node receiving the command:

    > CLUSTER DELSLOTS 5000 5001
    OK

Only 2 slots will be removed.

The following command removes the association from slots 5000 to
5200 from the node receiving the command:

    > CLUSTER DELSLOTSRANGE 5000 5200
    OK

201 slots will be removed.

However, note that:

1. The command only works if all the specified slots are already associated with the node.
2. The command fails if the same slot is specified multiple times.
3. As a side effect of the command execution, the node may go into *down* state because not all hash slots are covered.

## Usage in Redis Cluster

This command only works in cluster mode and may be useful for
debugging and in order to manually orchestrate a cluster configuration
when a new cluster is created. It is currently not used by `redis-cli`,
and mainly exists for API completeness.

@return

@simple-string-reply: `OK` if the command was successful. Otherwise
an error is returned.
