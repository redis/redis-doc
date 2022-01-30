This is a read-only variant of the `EVAL` command that cannot execute commands that modify data.

Unlike `EVAL`, scripts executed with this command can always be killed and never affect the replication stream.
Because the script can only read data, this command can always be executed on a master or a replica.

For more information about `EVAL` scripts please refer to [Introduction to Eval Scripts](/topics/eval-intro).

@examples

```
> SET mykey "Hello"
OK

> EVAL_RO "return redis.call('GET', KEYS[1])" 1 mykey
"Hello"

> EVAL_RO "return redis.call('DEL', KEYS[1])" 1 mykey
(error) ERR Error running script (call to f_359f69785f876b7f3f60597d81534f3d6c403284): @user_script:1: @user_script: 1: Write commands are not allowed from read-only scripts
```
