Load a script into the script cache, without executing it.
After the specified command is loaded into the script cache it will be callable using `EVALSHA` with the correct SHA1 digest of the script, exactly like after the first successful invocation of `EVAL`.

The script is guaranteed to stay in the script cache forever.
Forever means until the server is rebooted or `SCRIPT FLUSH` is called.

The command works in the same way even if the script was already present in the script cache.

For more information about `EVAL` scripts please refer to [Introduction to Eval Scripts](/topics/eval-intro).

@return

@bulk-string-reply: specifically, the SHA1 digest of the script added to the cache.
