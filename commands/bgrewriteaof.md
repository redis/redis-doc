Rewrites the [append-only file](/topics/persistence#append-only-file) to reflect the current dataset in memory.

If `BGREWRITEAOF` fails, no data gets lost as the old AOF will be untouched.

@return

@status-reply: always `OK`.
