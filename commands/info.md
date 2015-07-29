The `INFO` command returns information and statistics about the server in a
format that is simple to parse by computers and easy to read by humans.

The optional parameter can be used to select a specific section of information:

*   `server`: General information about the Redis server
*   `clients`: Client connections section
*   `memory`: Memory consumption related information
*   `persistence`: RDB and AOF related information
*   `stats`: General statistics
*   `replication`: Master/slave replication information
*   `cpu`: CPU consumption statistics
*   `commandstats`: Redis command statistics
*   `cluster`: Redis Cluster section
*   `keyspace`: Database related statistics

It can also take the following values:

*   `all`: Return all sections
*   `default`: Return only the default set of sections

When no parameter is provided, the `default` option is assumed.

@return

@bulk-string-reply: as a collection of text lines.

Lines can contain a section name (starting with a # character) or a property.
All the properties are in the form of `field:value` terminated by `\r\n`.

```cli
INFO
```

## Notes

Please note depending on the version of Redis some of the fields have been
added or removed. A robust client application should therefore parse the
result of this command by skipping unknown properties, and gracefully handle
missing fields.

Here is the description of fields for Redis >= 2.4.


Here is the meaning of all fields in the **server** section:

*   `redis_version`: Version of the Redis server
*   `redis_git_sha1`:  Git SHA1
*   `redis_git_dirty`: Git dirty flag
*   `os`: Operating system hosting the Redis server
*   `arch_bits`: Architecture (32 or 64 bits)
*   `multiplexing_api`: event loop mechanism used by Redis
*   `gcc_version`: Version of the GCC compiler used to compile the Redis server
*   `process_id`: PID of the server process
*   `run_id`: Random value identifying the Redis server (to be used by Sentinel and Cluster)
*   `tcp_port`: TCP/IP listen port
*   `uptime_in_seconds`: Number of seconds since Redis server start
*   `uptime_in_days`: Same value expressed in days
*   `lru_clock`: Clock incrementing every minute, for LRU management

Here is the meaning of all fields in the **clients** section:

*   `connected_clients`: Number of client connections (excluding connections from slaves)
*   `client_longest_output_list`: longest output list among current client connections
*   `client_biggest_input_buf`: biggest input buffer among current client connections
*   `blocked_clients`: Number of clients pending on a blocking call (BLPOP, BRPOP, BRPOPLPUSH)

Here is the meaning of all fields in the **memory** section:

*   `used_memory`:  total number of bytes allocated by Redis using its
     allocator (either standard **libc**, **jemalloc**, or an alternative allocator such
     as [**tcmalloc**][hcgcpgp]
*   `used_memory_human`: Human readable representation of previous value
*   `used_memory_rss`: Number of bytes that Redis allocated as seen by the
     operating system (a.k.a resident set size). This is the number reported by tools
     such as `top(1)` and `ps(1)`
*   `used_memory_peak`: Peak memory consumed by Redis (in bytes)
*   `used_memory_peak_human`: Human readable representation of previous value
*   `used_memory_lua`: Number of bytes used by the Lua engine
*   `mem_fragmentation_ratio`: Ratio between `used_memory_rss` and `used_memory`
*   `mem_allocator`: Memory allocator, chosen at compile time

Ideally, the `used_memory_rss` value should be only slightly higher than `used_memory`.
When rss >> used, a large difference means there is memory fragmentation
(internal or external), which can be evaluated by checking `mem_fragmentation_ratio`.
When used >> rss, it means part of Redis memory has been swapped off by the operating
system: expect some significant latencies.

Because Redis does not have control over how its allocations are mapped to
memory pages, high `used_memory_rss` is often the result of a spike in memory
usage.

When Redis frees memory, the memory is given back to the allocator, and the
allocator may or may not give the memory back to the system. There may be
a discrepancy between the `used_memory` value and memory consumption as
reported by the operating system. It may be due to the fact memory has been
used and released by Redis, but not given back to the system. The `used_memory_peak`
value is generally useful to check this point.

Here is the meaning of all fields in the **persistence** section:

*   `loading`: Flag indicating if the load of a dump file is on-going
*   `rdb_changes_since_last_save`: Number of changes since the last dump
*   `rdb_bgsave_in_progress`: Flag indicating a RDB save is on-going
*   `rdb_last_save_time`: Epoch-based timestamp of last successful RDB save
*   `rdb_last_bgsave_status`: Status of the last RDB save operation
*   `rdb_last_bgsave_time_sec`: Duration of the last RDB save operation in seconds
*   `rdb_current_bgsave_time_sec`: Duration of the on-going RDB save operation if any
*   `aof_enabled`: Flag indicating AOF logging is activated
*   `aof_rewrite_in_progress`: Flag indicating a AOF rewrite operation is on-going
*   `aof_rewrite_scheduled`: Flag indicating an AOF rewrite operation
     will be scheduled once the on-going RDB save is complete.
*   `aof_last_rewrite_time_sec`: Duration of the last AOF rewrite operation in seconds
*   `aof_current_rewrite_time_sec`: Duration of the on-going AOF rewrite operation if any
*   `aof_last_bgrewrite_status`: Status of the last AOF rewrite operation

`changes_since_last_save` refers to the number of operations that produced
some kind of changes in the dataset since the last time either `SAVE` or
`BGSAVE` was called.

If AOF is activated, these additional fields will be added:

*   `aof_current_size`: AOF current file size
*   `aof_base_size`: AOF file size on latest startup or rewrite
*   `aof_pending_rewrite`: Flag indicating an AOF rewrite operation
     will be scheduled once the on-going RDB save is complete.
*   `aof_buffer_length`: Size of the AOF buffer
*   `aof_rewrite_buffer_length`: Size of the AOF rewrite buffer
*   `aof_pending_bio_fsync`: Number of fsync pending jobs in background I/O queue
*   `aof_delayed_fsync`: Delayed fsync counter

If a load operation is on-going, these additional fields will be added:

*   `loading_start_time`: Epoch-based timestamp of the start of the load operation
*   `loading_total_bytes`: Total file size
*   `loading_loaded_bytes`: Number of bytes already loaded
*   `loading_loaded_perc`: Same value expressed as a percentage
*   `loading_eta_seconds`: ETA in seconds for the load to be complete

Here is the meaning of all fields in the **stats** section:

*   `total_connections_received`: Total number of connections accepted by the server
*   `total_commands_processed`: Total number of commands processed by the server
*   `instantaneous_ops_per_sec`: Number of commands processed per second
*   `rejected_connections`: Number of connections rejected because of `maxclients` limit
*   `expired_keys`: Total number of key expiration events
*   `evicted_keys`: Number of evicted keys due to `maxmemory` limit
*   `keyspace_hits`: Number of successful lookup of keys in the main dictionary
*   `keyspace_misses`: Number of failed lookup of keys in the main dictionary
*   `pubsub_channels`: Global number of pub/sub channels with client subscriptions
*   `pubsub_patterns`: Global number of pub/sub pattern with client subscriptions
*   `latest_fork_usec`: Duration of the latest fork operation in microseconds

Here is the meaning of all fields in the **replication** section:

*   `role`: Value is "master" if the instance is slave of no one, or "slave" if the instance is enslaved to a master.
    Note that a slave can be master of another slave (daisy chaining).

If the instance is a slave, these additional fields are provided:

*   `master_host`: Host or IP address of the master
*   `master_port`: Master listening TCP port
*   `master_link_status`: Status of the link (up/down)
*   `master_last_io_seconds_ago`: Number of seconds since the last interaction with master
*   `master_sync_in_progress`: Indicate the master is syncing to the slave

If a SYNC operation is on-going, these additional fields are provided:

*   `master_sync_left_bytes`: Number of bytes left before syncing is complete
*   `master_sync_last_io_seconds_ago`: Number of seconds since last transfer I/O during a SYNC operation

If the link between master and slave is down, an additional field is provided:

*   `master_link_down_since_seconds`: Number of seconds since the link is down

The following field is always provided:

*   `connected_slaves`: Number of connected slaves

For each slave, the following line is added:

*   `slaveXXX`: id, IP address, port, state

Here is the meaning of all fields in the **cpu** section:

*   `used_cpu_sys`: System CPU consumed by the Redis server
*   `used_cpu_user`:User CPU consumed by the Redis server
*   `used_cpu_sys_children`: System CPU consumed by the background processes
*   `used_cpu_user_children`: User CPU consumed by the background processes

The **commandstats** section provides statistics based on the command type,
including the number of calls, the total CPU time consumed by these commands,
and the average CPU consumed per command execution.

For each command type, the following line is added:

*   `cmdstat_XXX`: `calls=XXX,usec=XXX,usec_per_call=XXX`

The **cluster** section currently only contains a unique field:

*   `cluster_enabled`: Indicate Redis cluster is enabled

The **keyspace** section provides statistics on the main dictionary of each database.
The statistics are the number of keys, and the number of keys with an expiration.

For each database, the following line is added:

*   `dbXXX`: `keys=XXX,expires=XXX`

[hcgcpgp]: http://code.google.com/p/google-perftools/
