Gracefully asks the server to close the connection.
The connection is closed as soon as all pending replies have been written to the client.

{{% alert title="Note" color="info" %}}
Clients shouldn't use this command.

Instead, clients should simply close the connection when they're not used anymore.
Terminating a connection on the client side is preferable, as it eliminates `TIME_WAIT` lingering sockets on the server side.
{{% /alert  %}}

@return

@simple-string-reply: always `OK`.
