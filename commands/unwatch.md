@complexity

O(1).

Flushes all the previously watched keys for a [transaction](/topics/transactions).

If you call `EXEC` or `DISCARD`, there's no need to manually call `UNWATCH`.

@return

@status-reply: always `OK`.
