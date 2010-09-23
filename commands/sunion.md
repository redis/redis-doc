@complexity

O(N) where N is the total number of elements in all the provided
sets_

Return the members of a set resulting from the union of all the
sets hold at the specified keys. Like in LRANGE the result is sent to
the client as a multi-bulk reply (see the protocol specification for
more information). If just a single key is specified, then this command
produces the same result as [SMEMBERS][1].

Non existing keys are considered like empty sets.

@return

[Multi bulk reply][2], specifically the list of common elements.



[1]: /p/redis/wiki/SmembersCommand
[2]: /p/redis/wiki/ReplyTypes
