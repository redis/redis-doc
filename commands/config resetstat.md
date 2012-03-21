Resets the statistics reported by Redis using the `INFO` command.

These are the counters that are reset:

* Keyspace hits
* Keyspace misses
* Number of commands processed
* Number of connections received
* Number of expired keys

@return

@status-reply: always `OK`.
