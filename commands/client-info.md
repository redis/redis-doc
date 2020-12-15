The command returns information and statistics about the current client connection in a mostly human readable format.

The reply format is identical to that of `CLIENT LIST`, and the content consists only of information about the current client.

@examples

```
redis> CLIENT INFO
id=123 addr=127.0.0.1:65450 laddr=127.0.0.1:6379 fd=666 name=secretconn age=456 idle=0 flags=N db=0 sub=0 psub=0 multi=-1 qbuf=26 qbuf-free=45024 argv-mem=10 obl=0 oll=0 omem=0 tot-mem=62490 events=r cmd=client user=default redir=-1
```

@return

@bulk-string-reply: a unique string, as described at the `CLIENT LIST` page, for the current client.
