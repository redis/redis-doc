The `XACK` command removes one or multiple messages from the *Pending Entries List* (PEL) of a [Redis stream](/docs/data-types/streams) consumer group.

A message is pending, and as such stored inside the PEL, when it was delivered to some consumer, normally as a side effect of calling `XREADGROUP`, or when a consumer took ownership of a message calling `XCLAIM`.
The pending message was delivered to a consumer but the server isn't sure yet whether it was processed at least once.
So, new calls to `XREADGROUP` to grab the messages history for a consumer (for instance using an ID of 0), will return such messages.
Similarly, the pending message will be listed by the `XPENDING` command, which inspects the PEL.

Once a consumer *successfully* processes a message, it should call `XACK` so that such a message doesn't get processed again, and as a side effect, the PEL entry about this message is also purged, releasing memory from the Redis server.

@return

@integer-reply, specifically:

The command returns the number of messages successfully acknowledged.
Certain message IDs may no longer be part of the PEL (for example because they have already been acknowledged), and XACK will not count them as successfully acknowledged.

@examples

```
redis> XACK mystream mygroup 1526569495631-0
(integer) 1
```
