The command is identical to `CLIENT LIST`, but its reply only includes information about the current connection.

@examples

```
redis> CLIENT INFO
id=1 addr=127.0.0.1:12345 laddr=127.0.0.1:6379 fd=9 name= age=50 idle=0 flags=N db=0 sub=0 psub=0 ssub=0 multi=-1 qbuf=26 qbuf-free=16864 argv-mem=10 multi-mem=0 rbs=1024 rbp=0 obl=0 oll=0 omem=0 tot-mem=18730 events=r cmd=client|info user=default redir=-1 resp=2 lib-name=redis-rb lib-ver=1.2.3
```

@return

@bulk-string-reply: a unique string, as described at the `CLIENT LIST` page, for the current connection.
