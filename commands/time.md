The `TIME` command returns the current server time as a list with two items:

1. The Unix timestamp in seconds.
2. Microseconds count.

Basically, the interface is very similar to that of the `gettimeofday` system call.

@return

@array-reply, specifically, a two-element array consisting of the Unix timestamp in seconds and the microseconds' count.

@examples

```cli
TIME
TIME
```
