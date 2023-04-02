Lists the Pub/Sub channels that are active for the instance.

An active channel is a Pub/Sub channel with one or more subscribers (excluding clients subscribed to patterns).

If no _pattern_ is specified, all the channels are listed.
Otherwise, if a _pattern_ is specified, only channels matching the specified glob-style pattern are listed.

{{% alert title="Cluster note" color="info" %}}
In a Redis Cluster clients can subscribe to every node, and can also publish to every other node.
The cluster will make sure that published messages are forwarded as needed.
That said, `PUBSUB`'s replies in a cluster only report information from the node's Pub/Sub context, rather than the entire cluster.
{{% /alert  %}}

@return

@array-reply: a list of active channels, optionally matching the specified _pattern_.
