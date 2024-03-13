Invoke the execution of a server-side Lua script.

The first argument is the script's source code.
Scripts are written in [Lua](https://lua.org) and executed by the embedded [Lua 5.1](/topics/lua-api) interpreter in Redis.

The second argument is the number of input key name arguments, followed by all the keys accessed by the script.
These names of input keys are available to the script as the [_KEYS_ global runtime variable](/topics/lua-api#the-keys-global-variable)
Any additional input arguments **should not** represent names of keys.

**Important:**
to ensure the correct execution of scripts, both in standalone and clustered deployments, all names of keys that a script accesses must be explicitly provided as input key arguments.
The script **should only** access keys whose names are given as input arguments.
Scripts **should never** access keys with programmatically-generated names or based on the contents of data structures stored in the database.

**Important:**
in some cases, users will abuse lua eval.
Each `EVAL` call generates a new lua script, which is added to the lua interpreter and cached to redis-server, consuming a large amount of memory over time.
Since `EVAL` is mostly the one that abuses the lua cache, and these won't have pipeline issues (i.e. the script won't disappear unexpectedly, and cause errors like it would with `SCRIPT LOAD` and `EVALSHA`), we implement a plain FIFO LRU eviction only for these (not for scripts loaded with `SCRIPT LOAD`).
Starting from Redis 8.0, `EVAL` SCRIPTS will maintain an LRU list of length 500, when the number exceeds the limit, the oldest `EVAL` script will be evicted.
The number of evicted scripts can be viewed through `INFO`'s `evicted_scripts`.

Please refer to the [Redis Programmability](/topics/programmability) and [Introduction to Eval Scripts](/topics/eval-intro) for more information about Lua scripts.

@examples

The following example will run a script that returns the first argument that it gets.

```
> EVAL "return ARGV[1]" 0 hello
"hello"
```
