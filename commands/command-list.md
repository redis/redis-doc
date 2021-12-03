Returns @array-reply of command names in this Redis server.

The list can be filtered in the following ways:
 - Get commands that belong to s specific module
 - Get commands with a specific ACL categorie
 - Get command to comply with a specific regex pattern

@return

@array-reply: a full or filtered list of just the command names returned by `COMMAND`

@examples

```cli
COMMAND LIST
```
