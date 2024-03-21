Initiates a replication stream from the master.

The `SYNC` command is called by Redis replicas for initiating a replication
stream from the master. It has been replaced in newer versions of Redis by
 `PSYNC`.

For more information about replication in Redis please check the
[replication page][tr].

[tr]: /topics/replication
