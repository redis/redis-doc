The command behavior is the following:

* Stop all the clients.
* Perform a blocking SAVE if at least one **save point** is configured.
* Flush the Append Only File if AOF is enabled.
* Quit the server.

If persistence is enabled this commands makes sure that Redis is switched off
without the lost of any data.
This is not guaranteed if the client uses simply `SAVE` and then `QUIT` because
other clients may alter the DB data between the two commands.

Note: A Redis instance that is configured for not persisting on disk (no AOF
configured, nor "save" directive) will not dump the RDB file on `SHUTDOWN`, as
usually you don't want Redis instances used only for caching to block on when
shutting down.

## SAVE and NOSAVE modifiers

It is possible to specify an optional modifier to alter the behavior of the
command.
Specifically:

* **SHUTDOWN SAVE** will force a DB saving operation even if no save points are
  configured.
* **SHUTDOWN NOSAVE** will prevent a DB saving operation even if one or more
  save points are configured.
  (You can think of this variant as an hypothetical **ABORT** command that just
  stops the server).

@return

@simple-string-reply on error.
On success nothing is returned since the server quits and the connection is
closed.
