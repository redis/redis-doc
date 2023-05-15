A connection can use the `CLIENT TRACKING` command to enable [tracking](/topics/client-side-caching) notifications.
The connection can redirect the notifications to another connection.
This introspective command lets clients query the server about a connection's redirect status.

@return

@integer-reply: the ID of the client we are redirecting the notifications to.
The command returns `-1` if client tracking is not enabled, or `0` if client tracking is enabled but we are not redirecting the notifications to any client.
