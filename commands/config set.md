The `CONFIG SET` command is used in order to reconfigure the server at runtime
without the need to restart Redis. You can change both trivial parameters or
switch from one to another persistence option using this command.

The list of configuration parameters supported by `CONFIG SET` can be
obtained issuing a `CONFIG GET *` command, that is the symmetrical command
used to obtain information about the configuration of a running
Redis instance.

All the configuration parameters set using `CONFIG SET` are immediately loaded
by Redis that will start acting as specified starting from the next command
executed.

All the supported parameters have the same meaning of the equivalent
configuration parameter used in the [redis.conf](http://github.com/antirez/redis/raw/2.2/redis.conf) file, with the following important differences:

* Where bytes or other quantities are specified, it is not possible to use the redis.conf abbreviated form (10k 2gb ... and so forth), everything should be specified as a well formed 64 bit integer, in the base unit of the configuration directive.
* The save parameter is a single string of space separated integers. Every pair of integers represent a seconds/modifications threshold.

For instance what in redis.conf looks like:

    save 900 1
    save 300 10

that means, save after 900 seconds if there is at least 1 change to the
dataset, and after 300 seconds if there are at least 10 changes to the
datasets, should be set using `CONFIG SET` as "900 1 300 10".

It is possible to switch persistence form .rdb snapshotting to append only file
(and the other way around) using the `CONFIG SET` command. For more information
about how to do that please check [persistence page](/topics/persistence).

In general what you should know is that setting the *appendonly* parameter to
*yes* will start a background process to save the initial append only file
(obtained from the in memory data set), and will append all the subsequent
commands on the append only file, thus obtaining exactly the same effect of
a Redis server that started with AOF turned on since the start.

You can have both the AOF enabled with .rdb snapshotting if you want, the
two options are not mutually exclusive.

@return

@status-reply: `OK` when the configuration was set properly. Otherwise an error is returned.
