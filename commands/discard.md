Flushes all previously queued commands in a
[transaction](/topics/transactions) and restores the connection state to
normal.

If `WATCH` was used, `DISCARD` unwatches all keys.

@return

@status-reply: always `OK`.
