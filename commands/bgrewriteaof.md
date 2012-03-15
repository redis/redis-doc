Rewrites the [append-only file](/topics/persistence#append-only-file) to reflect the current dataset in memory.

If `BGREWRITEAOF` fails, no data gets lost as the old AOF will be untouched.

Please refer to the [persistence documentation](/topics/persistence) for detailed information about AOF rewriting.

@return

@status-reply: always `OK`.
