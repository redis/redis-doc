Return information about the function that's currently running.

The reply consists of the following information about the running script:

* **name:** the name of the function.
* **command:** the command and arguments used for invoking the function.
* **duration_ms:** the function's runtime duration in milliseconds.

If there's no in-flight function, the server replies with a _nil_.

In addition, the reply also includes returns the list of the function execution engines that are available.

You can use this command to inspect the invocation of a long-running function and decide whether kill it with the `FUNCTION KILL` command.

For more information please refer to [Introduction to Redis Functions](/topics/function)
