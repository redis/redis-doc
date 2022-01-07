Returns @array-reply (a flat representation of a map) of additional information
about commands, mostly for documentation purposes.
It contains the following fields:

 - `summary`
 - `since`
 - `group`
 - `complexity`
 - `doc-flags`
 - `deprecated-since`
 - `replaced-by`
 - `history`
 - `arguments`

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

An @array-reply of flags that are relevant for documentation purposes. Possible values:

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

## arguments

An @array-reply, where each element is a @map-reply describing a command argument.

For more information please check the [command-arguments page][td].
[td]: /topics/command-arguments

