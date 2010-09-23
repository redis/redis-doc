@complexity

O(1)


Atomically return and remove the last (tail) element of the _srckey_ list,
and push the element as the first (head) element of the _dstkey_ list. For
example if the source list contains the elements a,b,c and the
destination list contains the elements foo,bar after an RPOPLPUSH command
the content of the two lists will be a,b and c,foo,bar.

If the _key_ does not exist or the list is already empty the special
value 'nil' is returned. If the _srckey_ and _dstkey_ are the same the
operation is equivalent to removing the last element from the list and pusing
it as first element of the list, so it's a list rotation command.

## Programming patterns: safe queues

Redis lists are often used as queues in order to exchange messages between
different programs. A program can add a message performing an [LPUSH][1] operation
against a Redis list (we call this program a Producer), while another program
(that we call Consumer) can process the messages performing an [RPOP][2] command
in order to start reading the messages from the oldest.

Unfortunately if a Consumer crashes just after an [RPOP][2] operation the message
gets lost. RPOPLPUSH solves this problem since the returned message is
added to another backup list. The Consumer can later remove the message
from the backup list using the [LREM][3] command when the message was correctly
processed.

Another process, called Helper, can monitor the backup list to check for
timed out entries to repush against the main queue.

## Programming patterns: server-side O(N) list traversal

Using RPOPPUSH with the same source and destination key a process can
visit all the elements of an N-elements List in O(N) without to transfer
the full list from the server to the client in a single [LRANGE][4] operation.
Note that a process can traverse the list even while other processes
are actively RPUSHing against the list, and still no element will be skipped.

@return

@bulk-reply



[1]: /p/redis/wiki/RpushCommand
[2]: /p/redis/wiki/LpopCommand
[3]: /p/redis/wiki/LremCommand
[4]: /p/redis/wiki/LrangeCommand
[5]: /p/redis/wiki/ReplyTypes
