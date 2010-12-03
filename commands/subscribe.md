@complexity

O(1).

Subscribes the client to the given channel.

Once the client enters the subscripted state it is not supposed to issue
any other commands, expect for additional `SUBSCRIBE`, `PSUBSCRIBE`,
`UNSUBSCRIBE` and `PUNSUBSCRIBE` commands.
