This command is like `GEORADIUS`, but stores the result in destination.

It supports the `WITHDIST` option, can refer to `GEORADIUS`, but no additional destination key parameter is needed because the destination key has been specified in `argv[1]`.