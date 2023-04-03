The `SLOWLOG GET` command returns entries from the slow log in chronological order.

The Redis Slow Log is a system that logs queries that exceeded a specified execution time.
The execution time doesn't include I/O operations such as communicating with the client, sending the reply and so forth, but just the time needed to execute the command (this is the only stage of command execution where the thread is blocked and can not serve other requests in the meantime).

A new entry is added to the slow log whenever a command exceeds the execution time threshold defined by the `slowlog-log-slower-than` configuration directive.
The maximum number of entries in the slow log is governed by the `slowlog-max-len` configuration directive.

By default, the command returns the last ten entries in the log.
The optional _count_ argument limits the number of returned entries, so the command returns at most up to _count_ entries.

Each entry from the slow log is comprised of the following six values:

1. A unique progressive identifier for every slow log entry.
2. The Unix timestamp at which the logged command was processed.
3. The amount of time needed for its execution, in microseconds.
4. An array of the arguments of the command.
5. The client's IP address and port.
6. The client's name, if set via the `CLIENT SETNAME` command.

The entry's unique ID can be used to avoid processing slow log entries multiple times (for instance you may have a script sending you an email alert for every new slow log entry).
The ID is never reset in the course of the Redis server execution, only a server
restart will reset it.

@return

@array-reply: a list of slow log entries per the format above.
