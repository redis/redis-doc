Flushes all previously queued commands in a
[transaction][transactions] and restores the connection state to
normal.

[transactions]: /topics/transactions

If `WATCH` was used, `DISCARD` unwatches all keys.

@return

@status-reply: always `OK`.
