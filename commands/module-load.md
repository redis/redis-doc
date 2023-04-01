Loads a module from a dynamic library at runtime.

This command loads and initializes the Redis module from the dynamic library
specified by the `path` argument. The `path` should be the absolute path of the
library, including the full filename. Any additional arguments are passed
unmodified to the module.

**Note**: modules can also be loaded at server startup with `loadmodule`
configuration directive in `redis.conf`.

As of Redis v7.0, this command is disabled by default.
See the `enable-module-command` configuration directive in redis.conf for more details.

@return

@simple-string-reply: `OK` if module was loaded.
