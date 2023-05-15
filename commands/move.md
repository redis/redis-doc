Move _key_ from the currently selected database to the specified destination database.

See the `SELECT` command for more information about logical databases.

When the _key_ already exists in the destination _db_, or it doesn't exist in the source database, the command does nothing.
It is possible to use `MOVE` as a locking primitive because of this.

@return

@integer-reply, specifically:

* `1` if `key` was moved.
* `0` if `key` was not moved.
