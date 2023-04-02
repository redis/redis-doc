The `MEMORY PURGE` command attempts to purge dirty pages so these can be reclaimed by the allocator.

This command is currently implemented only when using **jemalloc** as an allocator and evaluates to a benign no-op for all others.

@return

@simple-string-reply
