Each entry of the reply's array is the definition of a single ACL user.
The format is the same as used in the redis.conf file, or the external ACL file.
That means you can copy-paste the reply into a configuration file if you wish (but make sure to also check `ACL SAVE`).

@return

@array-reply: specifically, an array of @bulk-string elements.

@examples

```
> ACL LIST
1) "user antirez on #9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08 ~objects:* &* +@all -@admin -@dangerous"
2) "user default on nopass ~* &* +@all"
```
