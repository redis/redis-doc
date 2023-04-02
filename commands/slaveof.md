The `SLAVEOF` command can change the replication settings of a replica on the fly.

If a Redis server is already acting as a replica, the command `SLAVEOF NO ONE` will turn off the replication, turning the Redis server into a _MASTER_.
In its other form, `SLAVEOF host port`, the command will make the server a replica of another server listening at the specified _host_ and _port_.

If a server is already a replica of another master, `SLAVEOF host port` will stop the replication from that server and start the synchronization against the new one, discarding the old dataset.

The form `SLAVEOF NO ONE` will stop replication, turning the server into a _MASTER_, but will not discard the replication.
So, if the old master stops working, it is possible to turn the replica into a master and set the application to use this new master in read/write.
Later when the other Redis server is fixed, it can be reconfigured to work as a replica.

@return

@simple-string-reply: `OK`.
