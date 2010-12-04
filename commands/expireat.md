@complexity

O(1)


Set a timeout on `key`. After the timeout has expired, the key will
automatically be deleted. A key with an associated timeout is said to be
_volatile_ in Redis terminology.

`EXPIREAT` has the same effect and semantic as `EXPIRE`, but instead of
specifying the number of seconds representing the TTL (time to live), it takes
an absolute [UNIX timestamp][2] (seconds since January 1, 1970).

[2]: http://en.wikipedia.org/wiki/Unix_time

## Background

`EXPIREAT` was introduced in order to convert relative timeouts to absolute
timeouts for the AOF persistence mode. Of course, it can be used directly to
specify that a given key should expire at a given time in the future.

@return

@integer-reply, specifically:

* `1` if the timeout was set.
* `0` if `key` does not exist or the timeout could not be set (see: `EXPIRE`).

