`CLIENT UNBLOCK` is a connections management command that unblocks a blocked
client.

The `client-id` should be the id of a client as returned by `CLIENT ID` and
`CLIENT LIST`.

The experience of being unblocked from the client's perspective can be modified
by providing an optional argument. The following reasons are available:

* `TIMEOUT`.
  This is the default reason, which will cause timeout-like behavior (meaning
  sending a @nil-reply to the client).
* `ERROR`.
  This reason will send the following error message to the blocked client:

```
-ERR UNBLOCKED client unblocked via CLIENT UNBLOCK
```

Note: unblocking is only possible for clients that are blocked by commands
operating on keys, such as `BLPOP`, `BZPOPMIN` and `XREAD`.
Using the command to unblock PubSub subscribers is not supported at this time.

@return

@integer-reply, specifically:

* `1` if the client was unblocked successfully.
* `0` if the client wasn't unblocked.
