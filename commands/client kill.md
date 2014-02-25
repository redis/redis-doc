The `CLIENT KILL` command closes a given client connection identified
by ip:port.

The ip:port should match a line returned by the `CLIENT LIST` command.

Due to the single-treaded nature of Redis, it is not possible to
kill a client connection while it is executing a command. From
the client point of view, the connection can never be closed
in the middle of the execution of a command. However, the client
will notice the connection has been closed only when the
next command is sent (and results in network error).

@return

@simple-string-reply: `OK` if the connection exists and has been closed
