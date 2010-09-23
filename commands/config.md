

The CONFIG command is able to retrieve or alter the configuration of a running
Redis server. Not all the configuration parameters are supported.

CONFIG has two sub commands, `GET` and `SET`. The `GET` command is used to read
the configuration, while the `SET` command is used to alter the configuration.

## CONFIG `GET` pattern

CONFIG `GET` returns the current configuration parameters. This sub command
only accepts a single argument, that is glob style pattern. All the
configuration parameters matching this parameter are reported as a
list of key-value pairs. Example:
    $ redis-cli config get '*'
    1. dbfilename
    2. dump.rdb
    3. requirepass
    4. (nil)
    5. masterauth
    6. (nil)
    7. maxmemory
    8. 0\n
    9. appendfsync
    10. everysec
    11. save
    12. 3600 1 300 100 60 10000
    
    $ redis-cli config get 'm*'
    1. masterauth
    2. (nil)
    3. maxmemory
    4. 0\n

The return type of the command is a @bulk-reply.

## CONFIG `SET` parameter  value

CONFIG `SET` is used in order to reconfigure the server, setting a specific
configuration parameter to a new value.

The list of configuration parameters supported by CONFIG `SET` can be
obtained issuing a CONFIG `GET` * command.

The configuration set using CONFIG `SET` is immediately loaded by the Redis
server that will start acting as specified starting from the next command.

Example:
    $ ./redis-cli
    redis set x 10
    OK
    redis config set maxmemory 200
    OK
    redis set y 20
    (error) ERR command not allowed when used memory  'maxmemory'
    redis config set maxmemory 0
    OK
    redis set y 20
    OK

## Parameters value forma

The value of the configuration parameter is the same as the one of the
same parameter in the Redis configuration file, with the following exceptions:

* The save paramter is a list of space-separated integers. Every pair of integers specify the time and number of changes limit to trigger a save. For instance the command CONFIG `SET` save 3600 10 60 10000 will configure the server to issue a background saving of the RDB file every 3600 seconds if there are at least 10 changes in the dataset, and every 60 seconds if there are at least 10000 changes. To completely disable automatic snapshots just set the parameter as an empty string.
* All the integer parameters representing memory are returned and accepted only using bytes as unit.

## See Also

The `INFO` command can be used in order to read configuriaton parameters
that are not available in the CONFIG command.



[1]: /p/redis/wiki/ReplyTypes
[2]: /p/redis/wiki/InfoCommand