Posts a message to the given shard channel.

In a Redis Cluster clients can publish to primary node (owner of the slot). The cluster makes sure
that published messages are forwarded to all the node in the shard, clients can subscribe to any
shard channel by connecting to any one of the nodes in the shard.

@return

@integer-reply: the number of clients that received the message.

## Example

For example the following command publish to channel `orders` with a subscriber already waiting for message(s).
    
        > 127.0.0.1:6379> spublish orders hello
          (integer) 1
