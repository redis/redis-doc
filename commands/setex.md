@complexity

O(1)


Set `key` to hold the string `value` and set `key` to timeout after a given
number of seconds.  This command is equivalent to exeucting the following
commands:

    SET key value
    EXPIRE key seconds

`SETEX` is atomic, and can be reproduced by using the previous two commands
inside an `MULTI`/`EXEC` block. It is provided as a faster alternative to the
given sequence of operations, because this operation is very common when Redis
is used as a cache.

An error is returned when `seconds` is invalid.

@return

@status-reply

