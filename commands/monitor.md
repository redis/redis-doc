

`MONITOR` is a debugging command that outputs the whole sequence of commands
received by the Redis server. is very handy in order to understand
what is happening into the database. This command is used directly
via telnet.
    % telnet 127.0.0.1 6379
    Trying 127.0.0.1...
    Connected to segnalo-local.com.
    Escape character is '^]'.
    MONITOR
    +OK
    monitor
    keys *
    dbsize
    set x 6
    foobar
    get x
    del x
    get x
    set key_x 5
    hello
    set key_y 5
    hello
    set key_z 5
    hello
    set foo_a 5
    hello
The ability to see all the requests processed by the server is useful in order
to spot bugs in the application both when using Redis as a database and as
a distributed caching system.

In order to end a monitoring session just issue a `QUIT` command by hand.

@return

**Non standard return value**, just dumps the received commands in an infinite
flow.