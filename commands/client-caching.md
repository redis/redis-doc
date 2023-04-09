When tracking is enabled in `OPTIN` or `OPTOUT` modes, this command controls the tracking of the keys in the next command executed by the connection.
Please check the [client side caching documentation](/topics/client-side-caching) for
background information.

When tracking is enabled by Redis, using the `CLIENT TRACKING` command, it is possible to specify the `OPTIN` or `OPTOUT` options, so that keys in read-only commands are not automatically remembered by the server to be invalidated later.
When we are in `OPTIN` mode, we can enable the tracking of the keys in the next command by calling `CLIENT CACHING yes` immediately before it.
Similarly, when we are in `OPTOUT` mode, and keys are normally tracked, we can avoid the keys in the next command being tracked using `CLIENT CACHING no`.

The command sets a state in the connection, that is valid only for the next command execution, which will modify the behavior of client tracking.

@return

@simple-string-reply: `OK` or an error if the argument is not "yes" or "no".
