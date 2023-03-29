The list of users may include usernames that do not exist.
In such cases, no operation is performed for the non-existing users.

{{% alert title="Note" color="info" %}}
The special `default` user cannot be removed from the system.
It is the user that's automatically assigned to all new connections.
{{% /alert  %}}

@return

@integer-reply: The number of users that were deleted.
This number won't always match the number of arguments, since certain users may not exist.

@examples

```
> ACL DELUSER antirez
1
```
