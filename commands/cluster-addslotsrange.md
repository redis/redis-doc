In function side, the `ADDSLOTSRANGE` command is very similar to `ADDSLOTS`, both of them
are to assign the passed hash slots to the node.

The difference is that `ADDSLOTS` assign the individual passed hash slot, and
`ADDSLOTSRANGE` will assign the hash slots based on the range ( between the start slot and end slot) 
specified as arguments.

## Example

If trying to assign slots 1 2 3 4 5 to the node, `ADDSLOTS` command is

    > CLUSTER ADDSLOTS 1 2 3 4 5
    OK

To finish the same operation, `ADDSLOTSRANGE` command is

    > CLUSTER ADDSLOTSRANGE 1 5
    OK


## Usage in Redis Cluster

This command only works in cluster mode and is useful in the following
Redis Cluster operations:

1. To create a new cluster ADDSLOTSRANGE is used in order to initially setup master nodes splitting the available hash slots among them.
2. In order to fix a broken cluster where certain slots are unassigned.

@return

@simple-string-reply: `OK` if the command was successful. Otherwise an error is returned.
