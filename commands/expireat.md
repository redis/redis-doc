`EXPIREAT` has the same effect and semantic as `EXPIRE`, but
instead of specifying the number of seconds representing the TTL (time to live), it takes an absolute [Unix timestamp][2] (seconds since January 1, 1970).

Please for the specific semantics of the command refer to the documentation of `EXPIRE`.

[2]: http://en.wikipedia.org/wiki/Unix_time

## Background

`EXPIREAT` was introduced in order to convert relative timeouts to absolute
timeouts for the AOF persistence mode. Of course, it can be used directly to
specify that a given key should expire at a given time in the future.

@return

@integer-reply, specifically:

* `1` if the timeout was set.
* `0` if `key` does not exist or the timeout could not be set (see: `EXPIRE`).

@examples

    @cli
    SET mykey "Hello"
    EXISTS mykey
    EXPIREAT mykey 1293840000
    EXISTS mykey

