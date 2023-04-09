Return the Unix timestamp of the last database successful save operation.
A client may check if a `BGSAVE` command succeeded by reading the `LASTSAVE` value, then issuing a `BGSAVE` command and checking at regular intervals every N seconds if `LASTSAVE` changed
Redis considers the database as successfully saved after startup.

@return

@integer-reply: a Unix timestamp.
