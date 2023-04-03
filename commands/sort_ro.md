This command is a read-only variant of the `SORT` command.
It is identical to `SORT`, but doesn't support the `STORE` option, and can safely be used on read-only replicas.

Since the original `SORT` has a `STORE` option it is technically flagged as a writing command in the Redis command table.
For that reason, read-only replicas in a Redis Cluster will redirect it to the master instance even if the connection is in read-only mode (see the `READONLY` command of Redis Cluster).

The `SORT_RO` variant was introduced to allow `SORT` behavior in read-only replicas without breaking compatibility on command flags.

See the original `SORT` for more details.

@examples

```
SORT_RO mylist BY weight_*->fieldname GET object_*->fieldname
```

@return

@array-reply: a list of sorted elements.
