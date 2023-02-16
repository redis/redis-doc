Subscribes the client to the specified channels.

Once the client enters the subscribed state it is not supposed to issue any
other commands, except for additional `SUBSCRIBE`, `SSUBSCRIBE`, `PSUBSCRIBE`, `UNSUBSCRIBE`, `SUNSUBSCRIBE`, 
`PUNSUBSCRIBE`, `PING`, `RESET` and `QUIT` commands.

When successful, this command doesn't return anything.
Instead, for each channel, one message with the first element being the string "subscribe" is pushed as a confirmation that command succeeded.

For more information, see [Pub/sub](/docs/manual/pubsub/).

## Behavior change history

*   `>= 6.2.0`: `RESET` can be called to exit subscribed state.
