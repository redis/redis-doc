@complexity

O(1)


The command is exactly equivalent to the following group of commands:
    SET _key_ _value_
    EXPIRE _key_ _time_The operation is atomic. An atomic [SET][1]+[EXPIRE][2]
operation was already provided
using `MULTI`/`EXEC`, but `SETEX` is a faster alternative provided
because this operation is very common when Redis is used as a Cache.

@return

@status-reply
