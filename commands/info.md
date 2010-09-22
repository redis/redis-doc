

The info command returns different information and statistics about the server in an format that's simple to parse by computers and easy to red by huamns.

## Return value

[Bulk reply][1], specifically in the following format:

	edis_version:0.07
	connected_clients:1
	connected_slaves:0
	used_memory:3187
	changes_since_last_save:0
	last_save_time:1237655729
	total_connections_received:1
	total_commands_processed:1
	uptime_in_seconds:25
	uptime_in_days:0

All the fields are in the form field:value

## Notes

* used_memory is returned in bytes, and is the total number of bytes allocated by the program using malloc.
* uptime_in_days is redundant since the uptime in seconds contains already the full uptime information, this field is only mainly present for humans.
* changes_since_last_save does not refer to the number of key changes, but to the number of operations that produced some kind of change in the dataset.



[1]: /p/redis/wiki/ReplyTypes
