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

@bulk-reply: in the following format (compacted for brevity):

```
redis_version:2.2.2
uptime_in_seconds:148
used_cpu_sys:0.01
used_cpu_user:0.03
used_memory:768384
used_memory_rss:1536000
mem_fragmentation_ratio:2.00
changes_since_last_save:118
keyspace_hits:174
keyspace_misses:37
allocation_stats:4=56,8=312,16=1498,...
db0:keys=1240,expires=0
```

All the fields are in the form of `field:value` terminated by `\r\n`.

## Notes

Please note depending on the version of Redis some of the fields have been
added or removed. A robust client application should therefore parse the
result of this command by skipping unknown property, and gracefully handle
missing fields.

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
     allocator (either standard `libc` `jemalloc`, or an alternative allocator such
     as [`tcmalloc`][hcgcpgp]
*   `used_memory_human`: Human readable representation of previous value
*   `used_memory_rss`: Number of bytes that Redis allocated as seen by the
     operating system (a.k.a resident set size). This is the number reported by tools
     such as `top` and `ps`.
*   `used_memory_peak`: Peak memory consumed by Redis (in bytes)
*   `used_memory_peak_human`: Human readable representation of previous value
*   `used_memory_lua`: Number of bytes used by the Lua engine
*   `mem_fragmentation_ratio`: Ratio between `used_memory_rss` and `used_memory`
*   `mem_allocator`: Memory allocator, chosen at compile time.

Ideally, the resident set size (rss) value should be close to `used_memory`.
A large difference between these numbers means there is memory fragmentation
(internal or external), represented by `mem_fragmentation_ratio`.

Because Redis does not have control over how its allocations are mapped to
memory pages, high `used_memory_rss` is often the result of a spike in memory
usage.

Here is the meaning of all fields in the **perstence** section:

*   `loading:0
*   `rdb_changes_since_last_save:0
*   `rdb_bgsave_in_progress:0
*   `rdb_last_save_time:1343589517
*   `rdb_last_bgsave_status:ok
*   `rdb_last_bgsave_time_sec:-1
*   `rdb_current_bgsave_time_sec:-1
*   `aof_enabled:0
*   `aof_rewrite_in_progress:0
*   `aof_rewrite_scheduled:0
*   `aof_last_rewrite_time_sec:-1
*   `aof_current_rewrite_time_sec:-1
*   `aof_last_bgrewrite_status:ok

Here is the meaning of all fields in the **stats** section:

*   `total_connections_received:1
*   `total_commands_processed:0
*   `instantaneous_ops_per_sec:0
*   `rejected_connections:0
*   `expired_keys:0
*   `evicted_keys:0
*   `keyspace_hits:0
*   `keyspace_misses:0
*   `pubsub_channels:0
*   `pubsub_patterns:0
*   `latest_fork_usec:0

Here is the meaning of all fields in the **replication** section:

*   `role:master
*   `connected_slaves:0

Here is the meaning of all fields in the **cpu** section:

*   `used_cpu_sys:0.06
*   `used_cpu_user:0.08
*   `used_cpu_sys_children:0.00
*   `used_cpu_user_children:0.00

Here is the meaning of all fields in the **commandstats** section:


Here is the meaning of all fields in the **cluster** section:

*   `cluster_enabled:0

Here is the meaning of all fields in the **keyspace** section:

db0:keys=3,expires=0



*   `changes_since_last_save` refers to the number of operations that produced
    some kind of change in the dataset since the last time either `SAVE` or
    `BGSAVE` was called.

*   `allocation_stats` holds a histogram containing the number of allocations of
    a certain size (up to 256).
    This provides a means of introspection for the type of allocations performed
    by Redis at run time.

[hcgcpgp]: http://code.google.com/p/google-perftools/
