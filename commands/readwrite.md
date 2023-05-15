Disables read-only queries for a connection to a Redis Cluster replica node.

Read-only queries against a Redis Cluster replica node are disabled by default, but you can use the `READONLY` command to change this behavior on a per-connection basis.
The `READWRITE` command resets the read-only mode flag of a connection back to read-write.

@return

@simple-string-reply: `OK`.
