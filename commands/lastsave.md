

Return the UNIX TIME of the last DB save executed with success.
A client may check if a [BGSAVE][1] command succeeded reading the LASTSAVE
value, then issuing a [BGSAVE][1] command and checking at regular intervals
every N seconds if LASTSAVE changed.

@return

@integer-reply, specifically an UNIX time stamp.



[1]: /p/redis/wiki/BgsaveCommand
[2]: /p/redis/wiki/ReplyTypes
