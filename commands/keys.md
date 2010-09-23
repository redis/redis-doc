@complexity

O(n) (with n being the number of keys in the DB, and assuming
keys and pattern of limited length)_

Returns all the keys matching the glob-style _pattern_ as
space separated strings. For example if you have in the
database the keys foo and foobar the command `KEYS` foo*
will return foo foobar.

Note that while the time complexity for this operation is O(n)
the constant times are pretty low. For example Redis running
on an entry level laptop can scan a 1 million keys database
in 40 milliseconds. **Still it's better to consider this one of
the slow commands that may ruin the DB performance if not used
with care**.

In other words this command is intended only for debugging and **special** operations like
creating a script to change the DB schema. Don't use it in your normal code. Use Redis
[Sets][1] in order to group together a subset of objects.

Glob style patterns examples:

* h?llo will match hello hallo hhllo
* h*llo will match hllo heeeello
* h[ae]llo will match hello and hallo, but not hillo

Use \ to escape special chars if you want to match them verbatim.

@return

@multi-bulk-reply



[1]: /p/redis/wiki/Sets
[2]: /p/redis/wiki/ReplyTypes