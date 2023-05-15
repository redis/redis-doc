The command lists the [Access Control List (ACL)](/docs/management/security/acl#acl-rules) rules that apply to the user and consist of:

* User flags
* Password hashes
* Command permissions
* Key patterns
* Channel patterns (added in Redis 6.2)
* Selectors (added in Redis 7.0)

Additional information may be returned in future versions of Redis.

Command rules are always returned in the same format as the one used in the `ACL SETUSER` command.
Before Redis 7.0, keys and channels were returned as an array of patterns.
However, in Redis 7.0 and above, they are now also returned in the same format as the one used in the `ACL SETUSER` command.

{{% alert title="Note" color="info" %}}
This description of command rules reflects the user's effective permissions, so while it may not be identical to the set of rules used to configure the user, it is still functionally identical.
{{% /alert %}}

Selectors are listed in the order they were applied to the user, and include information about commands, key patterns, and channel patterns.

@array-reply: a list of ACL rule definitions for the user.

If _user_ doesn't exist a @nil-reply is returned.

@examples

Here's an example configuration for a user

```
> ACL SETUSER sample on nopass +GET allkeys &* (+SET ~key2)
"OK"
> ACL GETUSER sample
1) "flags"
2) 1) "on"
   2) "allkeys"
   3) "nopass"
3) "passwords"
4) (empty array)
5) "commands"
6) "+@all"
7) "keys"
8) "~*"
9) "channels"
10) "&*"
11) "selectors"
12) 1) 1) "commands"
       6) "+SET"
       7) "keys"
       8) "~key2"
       9) "channels"
       10) "&*"
```
