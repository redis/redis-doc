New connections are authenticated with the `default` user. 
A connection can authenticate and switch users using either the `AUTH` or the `HELLO` command.

@return

@bulk-string-reply: the username of the current connection.

@examples

```
> ACL WHOAMI
"default"
```
