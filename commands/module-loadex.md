This is an extended version of the `MODULE LOAD` command.

It loads and initializes the Redis module from the dynamic library specified by the _path_ argument.
The _path_ should be the absolute path of the library, including the full filename.

You can use the optional `!CONFIG` argument to provide the module with configuration directives.
Any additional arguments that follow the `ARGS` keyword are passed unmodified to the module.

**Note**: modules can also be loaded at server startup with `loadmodule` configuration directive in _redis.conf_.

As of Redis v7.0, this command is disabled by default.
See the `enable-module-command` configuration directive in redis.conf for more details.

@return

@simple-string-reply: `OK` if the module was loaded.
