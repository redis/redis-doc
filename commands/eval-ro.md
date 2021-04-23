This is a variant of the `EVAL` command that can not execute commands that modify keys or values. So unlike `EVAL`, scripts executed with this command will not become unkillable and will never replicate traffic. This command can also always be routed to primaries or replicas and will execute consistently on both.

@examples

```cli
SET mykey "Hello"
EVAL_RO "return redis.call('GET', KEYS[1]);" 1 mykey
EVAL_RO "redis.call('DEL', KEYS[1]);" 1 mykey
```
