Subscribes the client to the [Redis Pub/Sub](/docs/manual/pubsub) specified channels.

Once a RESP2 client enters the subscribed state it isn't supposed to issue any other commands, except:

* `PING`
* `PSUBSCRIBE`
* `PUNSUBSCRIBE`
* `QUIT`
* `RESET`
* `SSUBSCRIBE`
* `SUBSCRIBE`
* `SUNSUBSCRIBE`
* `UNSUBSCRIBE`

However, if RESP3 is used (see `HELLO`), a client can issue any commands while in the subscribed state.

For more information, see [Pub/sub](/docs/manual/pubsub/).

@return

When successful, this command doesn't return anything.
Instead, for each channel, one message with the first element being the string "subscribe" is pushed as a confirmation that the command succeeded.

## Behavior change history

*   `>= 6.2.0`: `RESET` can be called to exit subscribed state.
