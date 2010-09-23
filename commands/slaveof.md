

The SLAVEOF command can change the replication settings of a slave on the fly.
If a Redis server is arleady acting as slave, the command SLAVEOF NO ONE
will turn off the replicaiton turning the Redis server into a MASTER.
In the proper form SLAVEOF hostname port will make the server a slave of the
specific server listening at the specified hostname and port.

If a server is already a slave of some master, SLAVEOF hostname port will
stop the replication against the old server and start the synchrnonization
against the new one discarding the old dataset.

The form SLAVEOF no one will stop replication turning the server into a
MASTER but will not discard the replication. So if the old master stop working
it is possible to turn the slave into a master and set the application to
use the new master in read/write. Later when the other Redis server will be
fixed it can be configured in order to work as slave.

@return

[Status code reply][1]



[1]: /p/redis/wiki/ReplyTypes
