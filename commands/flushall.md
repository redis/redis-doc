Delete all the keys of all the existing databases, not just the currently
selected one.
This command never fails.

The time-complexity for this operation is O(N), N being the number of
keys in all existing databases.

`SYNC` and `ASYNC`
---

`FLUSHALL`：flushes the database in an sync manner, but if **lazyfree-lazy-user-flush** (available since 6.2) is yes, it will be flushed asynchronously.  
`FLUSHALL SYNC`: flushes the database in an sync manner.(available since 6.2)  
`FLUSHALL ASYNC`: flushes the database in an async manner. (available since 4.0.0)  

Asynchronous `FLUSHALL` and `FLUSHDB` commands only delete keys that were present at the time the command was invoked. Keys created during an asynchronous flush will be unaffected.

@return

@simple-string-reply
