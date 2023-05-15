When no [Redis Pub/Sub](/docs/manual/pubsub) channels are specified, the client is unsubscribed from all the previously subscribed channels.
In this case, a message for every unsubscribed channel will be sent to the client.

@return

When successful, this command doesn't return anything.
Instead, for each channel, one message with the first element being the string "unsubscribe" is pushed as a confirmation that the command succeeded.
