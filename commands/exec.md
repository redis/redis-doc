Executes all previously queued commands in a
[transaction](/topics/transactions) and restores the connection state to
normal.

When using `WATCH`, `EXEC` will execute commands only if the
watched keys were not modified, allowing for a [check-and-set
mechanism](/topics/transactions#cas).

@return

@multi-bulk-reply: each element being the reply to each of the commands
in the atomic transaction.

When using `WATCH`, `EXEC` can return a @nil-reply if the execution was
aborted.
