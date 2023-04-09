Lists the [Redis Pub/Sub](/docs/manual/pubsub) channels that are active for the shard.

An active shard channel is a Pub/Sub shard channel with one or more subscribers.

If no _pattern_ is specified, all the channels are listed.
Otherwise, if a _pattern_ is specified, only channels matching the specified glob-style pattern are listed.

The information returned relates to the active channels at the shard's level, rather than at the cluster's level.

@return

@array-reply: a list of active channels, optionally matching the specified pattern.

@examples

```
> PUBSUB SHARDCHANNELS
1) "orders"
PUBSUB SHARDCHANNELS o*
1) "orders"
```
