The `XGROUP DELCONSUMER` command deletes the _consumer_ from the consumer _group_ of the [Redis stream](/docs/data-types/streams) at _key_.

Sometimes it may be useful to remove old consumers since they are no longer used.

Note, however, that any pending messages that the consumer had in the *Pending Entries List* (PEL)will become unclaimable after the consumer was deleted.
It is strongly recommended, therefore, that any pending messages are claimed or acknowledged before deleting the consumer from the group.

@return

@integer-reply: the number of pending messages that the _consumer_ had before it was deleted.
