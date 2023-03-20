This is a read-only variant of the `BITFIELD` command.
It only accepts the `!GET` subcommand, and can safely be used in read-only replicas.

Since the original `BITFIELD` has `!SET` and `!INCRBY` options, it is technically flagged as a writing command in the Redis commands table.
For this reason, read-only replicas in a Redis Cluster will redirect it to the master instance even if the connection is in read-only mode (see the `READONLY` command of Redis Cluster).

Since Redis 6.2, the `BITFIELD_RO` variant was introduced to support `BITFIELD`'s functionality in read-only replicas, without breaking compatibility on command flags.

See the `BITFIELD` for more details regarding the usage.

@examples

```
BITFIELD_RO hello GET i8 16
```

@return

@array-reply: An array of @number-reply, each entry being the result of the corresponding subcommand.
