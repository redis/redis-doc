# Command information

Starting from Redis 7.0 we include an additional map in `COMMAND`'s reply, which contains the following fields:

 - `summary`
 - `since`
 - `group`
 - `complexity`
 - `doc-flags`
 - `deprecated-since`
 - `replaced-by`
 - `history`
 - `hints`
 - `arguments`
 - `key-specs`
 - `subcommands`

Only `summary`, `since`, and `group` are mandatory, the rest may be absent.

## summary

Short command description.

## since

The Redis version in which the command was added.

## group


The functional group to which the command belongs. Possible values:

 - generic
 - string
 - list
 - set
 - sorted-set
 - hash
 - pubsub
 - transactions
 - connection
 - server
 - scripting
 - hyperloglog
 - cluster
 - sentinel
 - geo
 - stream
 - bitmap
 - module

## complexity

A short explanation about the command's time complexity.

## doc-flags

An @array-reply of flgas that are relevant for documentation purposes. Possible values:

 - deprecated: the command is deprecated
 - syscmd: a system command that isn't meant to be called by users

## deprecated-since

For deprecated commands, this is the Redis version from which the command is deprecated.

## replaced-by

For deprecated commands, this is the alternative for the deprecated command.

## history

An @array-reply, where each element is also an @array-reply with two elements:

1. The version when something changed about the command interface
2. A short description of the change

## hints

An @array-reply of hints that are meant to help clients/proxies know how to handle the command.

For more information please check the [command-hints page][tc].
[tc]: /topics/command-hints

## arguments

An @array-reply, where each element is a @map-reply describing a command argument.

For more information please check the [command-arguments page][td].
[td]: /topics/command-arguments

## key-specs

An @array-reply, where each element is a @map-reply describing a method to locate keys within the arguments.
For more information please check the [key-specs page][tr].
[tr]: /topics/key-specs

## subcommands

Some commands have subcommands (Example: `REWRITE` is a subcommand of `CONFIG`).
This is an @array-reply, with the same format and specification of `COMMAND`'s reply.

