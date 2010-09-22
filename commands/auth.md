

Request for authentication in a password protected Redis server.
A Redis server can be instructed to require a password before to allow clients
to issue commands. This is done using the _requirepass_ directive in the
Redis configuration file.

If the password given by the client is correct the server replies with
an OK status code reply and starts accepting commands from the client.
Otherwise an error is returned and the clients needs to try a new password.
Note that for the high performance nature of Redis it is possible to try
a lot of passwords in parallel in very short time, so make sure to generate
a strong and very long password so that this attack is infeasible.

## Return value

[Status code reply][1]



[1]: /p/redis/wiki/ReplyTypes
