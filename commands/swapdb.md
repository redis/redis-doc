This new command swaps two Redis databases, so that immediately all the
clients connected to a given DB will see the data of the other DB, and
the other way around. Example:

    SWAPDB 0 1

This will swap DB 0 with DB 1. All the clients connected with DB 0 will
immediately see the new data, exactly like all the clients connected
with DB 1 will see the data that was formerly of DB 0.

@return

@simple-string-reply: `OK` if `SWAPDB` was executed correctly.

@examples

```cli
SWAPDB 0 1
```
