Posts the _message_ to the given [Redis Pub/Sub](/docs/manual/pubsub) _channel_.

{{% alert title="Cluster note" color="info" %}}
In a Redis Cluster, clients can publish to every node.
The cluster makes sure that published messages are forwarded as needed, so clients can subscribe to any channel by connecting to any one of the nodes.
{{% /alert %}}

@return

@integer-reply: the number of clients that received the message.

Note that in a Redis Cluster, only clients that are connected to the same node as the publishing client are included in the count.
