The `MEMORY STATS` command returns an @array-reply about the memory usage of the
server.

The information about memory usage is provided as metrics and their respective
values. The following metrics are reported:

*   `peak.allocated`: Peak memory consumed by Redis in bytes (see `INFO`'s
     `used_memory_peak`)
*   `total.allocated`: Total number of bytes allocated by Redis using its
     allocator (see `INFO`'s `used_memory`)
*   `startup.allocated`: Initial amount of memory consumed by Redis at startup
     in bytes (see `INFO`'s `used_memory_startup`)
*   `replication.backlog`: Size in bytes of the replication backlog (see
     `INFO`'s `repl_backlog_active`)
*   `clients.slaves`: The total size in bytes of all replicas overheads (output
     and query buffers, connection contexts)
*   `clients.normal`: The total size in bytes of all clients overheads (output
     and query buffers, connection contexts)
*   `cluster.links`: Memory usage by cluster links (Added in Redis 7.0, see `INFO`'s `mem_cluster_links`).
*   `aof.buffer`: The summed size in bytes of AOF related buffers.
*   `lua.caches`: the summed size in bytes of the overheads of the Lua scripts'
     caches
*   `dbXXX`: For each of the server's databases, the overheads of the main and
     expiry dictionaries (`overhead.hashtable.main` and
    `overhead.hashtable.expires`, respectively) are reported in bytes
*   `overhead.hashtable.lut`: Total overhead of dictionary buckets in databases (Added in Redis 8.0)
*   `overhead.hashtable.rehashing`: Temporary memory overhead of database dictionaries currently being rehashed (Added in Redis 8.0) 
*   `overhead.total`: The sum of all overheads, i.e. `startup.allocated`,
     `replication.backlog`, `clients.slaves`, `clients.normal`, `aof.buffer` and
     those of the internal data structures that are used in managing the
     Redis keyspace (see `INFO`'s `used_memory_overhead`)
*   `database.dict.rehashing.count`: Number of DB dictionaries currently being rehashed (Added in Redis 8.0)
*   `keys.count`: The total number of keys stored across all databases in the
     server
*   `keys.bytes-per-key`: The ratio between `dataset.bytes` and `keys.count` 
*   `dataset.bytes`: The size in bytes of the dataset, i.e. `overhead.total`
     subtracted from `total.allocated` (see `INFO`'s `used_memory_dataset`)
*   `dataset.percentage`: The percentage of `dataset.bytes` out of the total
     memory usage
*   `peak.percentage`: The percentage of `total.allocated` out of
     `peak.allocated`
*   `fragmentation`: See `INFO`'s `mem_fragmentation_ratio`

**A note about the word slave used in this man page**: Starting with Redis 5, if not for backward compatibility, the Redis project no longer uses the word slave. Unfortunately in this command the word slave is part of the protocol, so we'll be able to remove such occurrences only when this API will be naturally deprecated.
