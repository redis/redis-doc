
Stop all the clients, save the DB (if saving is configured), then quit the server.
This commands makes sure that the DB is switched off without the lost of any data.
This is not guaranteed if the client uses simply `SAVE` and then
`QUIT` because other clients may alter the DB data between the two
commands.

@return

@status-reply on error. On success nothing is returned since the server
quits and the connection is closed.
