Delete all the keys of all the existing databases, not just the currently
selected one.
This command never fails.

The time-complexity for this operation is O(N), N being the number of
keys in all existing databases.

`FLUSHALL` ASYNC (Redis 4.0.0 or greater)
---
Code name "lazy freeing of objects", but it's a lame name for a neat feature.
There is a new command called `UNLINK` that just deletes a key reference in the database, and does the actual clean up of the allocations in a separated thread, so if you use `UNLINK` instead of `DEL` against a huge key the server will not block.
And even better with the ASYNC options of `FLUSHALL` and `FLUSHDB` you can do that for whole dbs or for all the data inside the instance, if you want. Combined with the new `SWAPDB` command, that swaps two Redis databases content, `FLUSHDB` ASYNC can be quite interesting.
Once you, for instance, populated db 1 with the new version of the data, you can `SWAPDB` 0 1 and `FLUSHDB` ASYNC the database with the old data, and create yet a newer version and reiterate. This is only possible now because flushing a whole db is no longer blocking.

@return

@simple-string-reply
