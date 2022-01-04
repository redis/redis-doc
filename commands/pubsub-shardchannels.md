Lists the currently *active shard channels*.

An active shard channel is a Pub/Sub shard channel with one or more subscribers.

If no `pattern` is specified, all the channels are listed, otherwise if pattern is specified only channels matching the specified glob-style pattern are listed.

Cluster note: `PUBSUB`'s replies in a cluster only report information from the node's Pub/Sub context, rather than the entire cluster.

@return

@array-reply: a list of active channels, optionally matching the specified pattern.

## Example

        > PUBSUB SHARDCHANNELS
          1) "orders"
          PUBSUB SHARDCHANNELS o*
          1) "orders"

