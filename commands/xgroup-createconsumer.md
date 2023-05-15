Create a consumer named _consumername_ in the consumer group _groupname_ of the [Redis stream](/docs/data-types/streams) that's stored at _key_.

Consumers are also created automatically whenever an operation, such as `XREADGROUP`, references a consumer that doesn't exist.
This is valid for `XREADGROUP` only when the stream has entries in it.

@return

@integer-reply: the number of created consumers (either 0 or 1).
