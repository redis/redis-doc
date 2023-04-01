Unloads a module.

This command unloads the module specified by `name`. Note that the module's name
is reported by the `MODULE LIST` command, and may differ from the dynamic
library's filename.

Known limitations:

*   Modules that register custom data types can not be unloaded.

As of Redis v7.0, this command is disabled by default.
See the `enable-module-command` configuration directive in redis.conf for more details.

@return

@simple-string-reply: `OK` if module was unloaded.
