The `CONFIG SET` command is used to reconfigure the server at run time without the need to restart Redis.
You can change most parameters, including switching from one persistence option to another.

The list of configuration parameters can be obtained by issuing a `CONFIG GET *` command.
`CONFIG GET` can be used to obtain information about the configuration of a running Redis instance.

All configuration parameters set using `CONFIG SET` are immediately loaded by Redis and will take effect starting with the next command executed.
Changes to configuration parameters **aren't persisted** automatically.
To persist the changes use the `CONFIG REWRITE` command.

All the supported parameters have the same meaning as those in the [redis.conf][hgcarr22rc] file.

[hgcarr22rc]: http://github.com/redis/redis/raw/unstable/redis.conf

Note that you should look at the redis.conf file that applies to the version you're working with, as configuration options might change between versions.
The link above is to the latest development version.

It is possible to switch persistence from RDB snapshotting to append-only file (or any other combination) using the `CONFIG SET` command.
For more information about how to do that please check the [persistence page][tp].

Basically, setting the `appendonly` parameter to `yes`, will start a background process to save the initial append-only file (obtained from the in-memory data set).
It will append all the subsequent commands on the append-only file, thus having the same effect as a Redis server that started with AOF turned on since the start.

You can have both the AOF enabled with RDB snapshotting if you want, the two options are not mutually exclusive.

@return

@simple-string-reply: `OK` when the configuration was set properly.
Otherwise an error is returned.
