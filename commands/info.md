The `INFO` command returns information and statistics about the server
in format that is simple to parse by computers and easy to red by humans.

@return

@bulk-reply: in the following format (compacted for brevity):

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

All the fields are in the form of `field:value` terminated by `\r\n`.

## Notes

* `used_memory` is the total number of bytes allocated by Redis using its
  allocator (either standard `libc` `malloc`, or an alternative allocator such as
  [`tcmalloc`][1]

* `used_memory_rss` is the number of bytes that Redis allocated as seen by the
  operating system. Optimally, this number is close to `used_memory` and there
  is little memory fragmentation. This is the number reported by tools such as
  `top` and `ps`. A large difference between these numbers means there is
  memory fragmentation. Because Redis does not have control over how its
  allocations are mapped to memory pages, `used_memory_rss` is often the result
  of a spike in memory usage. The ratio between `used_memory_rss` and
  `used_memory` is given as `mem_fragmentation_ratio`.

* `changes_since_last_save` refers to the number of operations that produced
  some kind of change in the dataset since the last time either `SAVE` or
  `BGSAVE` was called.

* `allocation_stats` holds a histogram containing the number of allocations of
  a certain size (up to 256). This provides a means of introspection for the
  type of allocations performed by Redis at run time.

[1]: http://code.google.com/p/google-perftools/
