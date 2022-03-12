Subscribes the client to the specified shard channels.

In a Redis cluster, shard channels are assigned to slots by the same algorithm used to assign keys to slots. 
Client(s) can subscribe to a node covering a slot (primary/replica) to receive the messages published.

For more information about sharded pubsub, see [Sharded Pubsub](/topics/pubsub#sharded-pubsub). 

@examples

```
> ssubscribe orders
Reading messages... (press Ctrl-C to quit)
1) "ssubscribe"
2) "orders"
3) (integer) 1
1) "message"
2) "orders"
3) "hello"
```
