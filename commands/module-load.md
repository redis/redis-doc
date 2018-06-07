Loads a module from a dynamic library at runtime.

This command loads and initializes the Redis module from the dynamic library
specified by the `path` argument. The `path` should be the absolute path,
including the full filename, of the library. Any additional arguments are passed
unmodified to the module.

**Note**: modules can also be loaded at server startup with 'loadmodule'
configuration directive in `redis.conf`.

@return

@simple-string-reply: `OK` if module was loaded.

