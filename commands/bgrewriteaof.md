Instruct Redis to start an [Append Only File][aof] rewrite process. The rewrite will create a small optimized version of the current Append Only File.

[aof]: /topics/persistence#append-only-file

If `BGREWRITEAOF` fails, no data gets lost as the old AOF will be untouched.

The rewrite will be only triggered by Redis if there is not already a background process doing persistence. Specifically:

* If a Redis child is creating a snapshot on disk, the AOF rewrite is *scheduled* but not started until the saving child producing the RDB file terminates. In this case the `BGREWRITEAOF` will still return an OK code, but with an appropriate message. You can check if an AOF rewrite is scheduled looking at the `INFO` command starting from Redis 2.6.
* If an AOF rewrite is already in progress the command returns an error and no AOF rewrite will be scheduled for a later time.

Since Redis 2.4 the AOF rewrite is automatically triggered by Redis, however the `BGREWRITEAOF` command can be used to trigger a rewrite at any time.

Please refer to the [persistence documentation][persistence] for detailed information.

[persistence]: /topics/persistence

@return

@status-reply: always `OK`.
