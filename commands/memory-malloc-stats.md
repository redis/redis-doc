The `MEMORY MALLOC-STATS` command provides an internal statistics report from the memory allocator.

This command is currently implemented only when using **jemalloc** as an allocator and evaluates to a benign no-op for all others.

@return

@bulk-string-reply: the memory allocator's internal statistics report
