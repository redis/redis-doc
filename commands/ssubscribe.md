Subscribes the client to the specified shard channels.

In a Redis cluster, shard channels are hashed to a slot and client can subscribe to a node covering a slot (primary/replica) 
to recieve the messages published. 
 
Once the client enters the subscribed state it is not supposed to issue any
other commands, except for additional `SUBSCRIBE`, `SSUBSCRIBE`, `PSUBSCRIBE`, `UNSUBSCRIBE`,
`PUNSUBSCRIBE`, `PING`, `RESET` and `QUIT` commands.


## Example

        > 127.0.0.1:6379> ssubscribe orders
          Reading messages... (press Ctrl-C to quit)
          1) "ssubscribe"
          2) "orders"
          3) (integer) 1
          1) "message"
          2) "orders"
          3) "hello"
          
          


