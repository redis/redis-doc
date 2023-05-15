This command resets the statistics reported by Redis via the `INFO` and `LATENCY HISTOGRAM` commands.

The following is a non-exhaustive list of values that are reset:

* Keyspace hits and misses.
* The number of expired keys.
* Command and error statistics.
* Connections received, rejected and evicted.
* Persistence statistics.
* Active defragmentation statistics.

@return

@simple-string-reply: always `OK`.
