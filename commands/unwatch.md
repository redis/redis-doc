Flushes all the previously watched keys for a [transaction][tt].

[tt]: /topics/transactions

There's no need to call `UNWATCH` after calling `EXEC` or `DISCARD`.

@return

@simple-string-reply: always `OK`.
