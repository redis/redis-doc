Save the DB in background. The OK code is immediately returned. Redis forks,
the parent continues to server the clients, the child saves the DB on disk
then exit. A client my be able to check if the operation succeeded using the
`LASTSAVE` command.

Please refer to the [persistence documentation][tp] for detailed information.

[tp]: /topics/persistence

@return

@status-reply
