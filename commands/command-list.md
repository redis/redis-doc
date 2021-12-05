Returns @array-reply of command names in this Redis server.

The list can be filtered in the following ways:

 - **`MODULE module-name`**: get the commands that belong to a module
 - **`ACLCAT category`**: get the commands in a specific ACL category
 - **`PATTERN pattern`**: get the commands that match the given glob-like pattern

@return

@array-reply: a list of command names.

@examples

```cli
COMMAND LIST
```
