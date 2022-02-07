Return documentary information about commands.

By default, the reply includes all of the server's commands.
You can use the optional _command-name_ argument to specify the names of one or more commands.

The reply includes a map for each returned command.
The following keys are always present in the reply:

* **summary:** short command description.
* **since:** the Redis version that added the command.
* **group:** the functional group to which the command belongs.
  Possible values are:
  - _bitmap_
  - _cluster_
  - _connection_
  - _generic_
  - _geo_
  - _hash_
  - _hyperloglog_
  - _list_
  - _module_
  - _pubsub_
  - _scripting_
  - _sentinel_
  - _server_
  - _set_
  - _sorted-set_
  - _stream_
  - _string_
  - _transactions_

The following keys may be included in the mapped reply as well:

* **complexity:** a short explanation about the command's time complexity.
* **doc-flags:** an array of documentation flags.
  Possible values are:
  - _deprecated:_ the command is deprecated.
  - _syscmd:_ a system command that isn't meant to be called by users.
* **deprecated-since:** the Redis version that deprecated the command.
* **replaced-by:** the alternative for a deprecated command.
* **history:** an array of historical notes describing changes to the command's behavior or arguments.
  Each entry is an array itself, made up of two elements:
  1. The Redis version that the entry applies to.
  2. The description of the change.
* **arguments:** an array of maps that describe the command's arguments.
  Please refer to the [Redis command arguments][td] page for more information.

[td]: /topics/command-arguments

@return

@array-reply: a map as a flattened array as described above.

@examples

```cli
COMMAND DOCS SET
```
