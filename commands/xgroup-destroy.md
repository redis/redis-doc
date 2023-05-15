The `XGROUP DESTROY` command removes the consumer _group_ and all the information that's associated with it from the [Redis stream](/docs/data-types/streams) at _key_.

The consumer group will be destroyed even if there are active consumers, and pending messages, so make sure to call this command only when needed.

@return

@integer-reply: the number of destroyed consumer groups (0 or 1).
