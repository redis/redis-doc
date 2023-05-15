Returns the number of [Redis Pub/Sub](/docs/manual/pubsub) subscribers for the specified shard channels.

Note that it is valid to call this command without channels.
In this case, the command will return an empty list.

{{% alert title="Cluster note" color="info" %}}
In a Redis Cluster, `PUBSUB`'s replies in a cluster only report information from the node's Pub/Sub context, rather than the entire cluster.
{{% /alert %}}

@return

@array-reply: a list of channels and the number of subscribers for every channel.

The format is channel, count, channel, count, ..., so the list is flat.
The order in which the channels are listed is the same as the order of the shard channels specified in the command call.

@examples

```
> PUBSUB SHARDNUMSUB orders
1) "orders"
2) (integer) 1
```
