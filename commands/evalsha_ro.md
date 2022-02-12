This is a read-only variant of the `EVALSHA` command that cannot execute commands that modify data.

Unlike `EVALSHA`, scripts executed with this command can always be killed and never affect the replication stream.
Because it can only read data, this command can always be executed on a master or a replica.

For more information about `EVALSHA` scripts please refer to [Introduction to Eval Scripts](/topics/eval-intro).
