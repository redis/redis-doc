The command behavior is the following:

* Stop all the clients.
* Blocking save the RDB file of teh current data set If at least one **save point** is configured.
* Flush the Append Only File if AOF is enabled.
* Quit the server.

If persistence is enabled this commands makes sure that Redis is switched
off without the lost of any data. This is not guaranteed if the client uses
simply `SAVE` and then `QUIT` because other clients may alter the DB data
between the two commands.

Note: A Redis instance that is configured for not persisting on disk
(no AOF configured, nor "save" directive) will not dump the RDB file on
`SHUTDOWN`, as usually you don't want Redis instances used only for caching
to block on when shutting down.

@return

@status-reply on error. On success nothing is returned since the server
quits and the connection is closed.
