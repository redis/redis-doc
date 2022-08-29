---
title: "Redis command arguments"
linkTitle: "Command arguments"
weight: 1
description: How Redis commands expose their documentation programmatically
aliases:
    - /topics/command-arguments
---

The `COMMAND DOCS` command returns documentation-focused information about available Redis commands.
The map reply that the command returns includes the _arguments_ key.
This key stores an array that describes the command's arguments.

Every element in the _arguments_ array is a map with the following fields:

* **name:** the argument's name, always present.
  The name is displayed during the command's syntax rendering as a placeholder for user input.
* **type:** the argument's type, always present.
  An argument must have one of the following types:
  - **string:** a string argument.
  - **integer:** an integer argument.
  - **double:** a double-precision argument.
  - **key:** a string that represents the name of a key.
  - **pattern:** a string that represents a glob-like pattern.
  - **unix-time:** an integer that represents a Unix timestamp.
  - **pure-token:** an argument is a token, meaning a reserved keyword, which may or may not be provided. 
    Not to be confused with free-text user input.
  - **oneof**: the argument is a container for nested arguments.
    This type enables choice among several nested arguments (see the `XADD` example below).
  - **block:** the argument is a container for nested arguments.
    This type enables grouping arguments and applying a property (such as _optional_) to all (see the `XADD` example below).
* **key_spec_index:** this value is available for every argument of the _key_ type.
  It is a 0-based index of the specification in the command's [key specifications][tr] that corresponds to the argument.
* **token**: a constant literal that precedes the argument (user input) itself.
* **summary:** a short description of the argument.
* **since:** the debut Redis version of the argument (or for module commands, the module version).
* **deprecated_since:** the Redis version that deprecated the command (or for module commands, the module version).
* **flags:** an array of argument flags.
  Possible flags are:
  - **optional**: denotes that the argument is optional (for example, the _GET_ clause of the  `SET` command).
  - **multiple**: denotes that the argument may be repeated (such as the _key_ argument of `DEL`).
  - **multiple-token:** denotes the possible repetition of the argument with its preceding token (see `SORT`'s `GET pattern` clause).
* **arguments:** nested arguments.
  For the _oneof_ and _block_ types, this is an array of nested arguments, each being a map as described in this section.

[tr]: /topics/key-specs

## Example

The trimming clause of `XADD`, i.e., `[MAXLEN|MINID [=|~] threshold [LIMIT count]]`, is represented at the top-level as _block_-typed argument.

It consists of four nested arguments:

1. **trimming strategy:** this nested argument has an _oneof_ type with two nested arguments.
  Each of the nested arguments, _MAXLEN_ and _MINID_, is typed as _pure-token_.
2. **trimming operator:** this nested argument is an optional _oneof_ type with two nested arguments.
  Each of the nested arguments, _=_ and _~_, is a _pure-token_.
3. **threshold:** this nested argument is a _string_.
4. **count:** this nested argument is an optional _integer_ with a _token_ (_LIMIT_).

Here's `XADD`'s arguments array:

```
1) 1) "name"
   2) "key"
   3) "type"
   4) "key"
   5) "value"
   6) "key"
2)  1) "name"
    2) "nomkstream"
    3) "type"
    4) "pure-token"
    5) "token"
    6) "NOMKSTREAM"
    7) "since"
    8) "6.2"
    9) "flags"
   10) 1) optional
3) 1) "name"
   2) "trim"
   3) "type"
   4) "block"
   5) "flags"
   6) 1) optional
   7) "value"
   8) 1) 1) "name"
         2) "strategy"
         3) "type"
         4) "oneof"
         5) "value"
         6) 1) 1) "name"
               2) "maxlen"
               3) "type"
               4) "pure-token"
               5) "token"
               6) "MAXLEN"
            2) 1) "name"
               2) "minid"
               3) "type"
               4) "pure-token"
               5) "token"
               6) "MINID"
               7) "since"
               8) "6.2"
      2) 1) "name"
         2) "operator"
         3) "type"
         4) "oneof"
         5) "flags"
         6) 1) optional
         7) "value"
         8) 1) 1) "name"
               2) "equal"
               3) "type"
               4) "pure-token"
               5) "token"
               6) "="
            2) 1) "name"
               2) "approximately"
               3) "type"
               4) "pure-token"
               5) "token"
               6) "~"
      3) 1) "name"
         2) "threshold"
         3) "type"
         4) "string"
         5) "value"
         6) "threshold"
      4)  1) "name"
          2) "count"
          3) "type"
          4) "integer"
          5) "token"
          6) "LIMIT"
          7) "since"
          8) "6.2"
          9) "flags"
         10) 1) optional
         11) "value"
         12) "count"
4) 1) "name"
   2) "id_or_auto"
   3) "type"
   4) "oneof"
   5) "value"
   6) 1) 1) "name"
         2) "auto_id"
         3) "type"
         4) "pure-token"
         5) "token"
         6) "*"
      2) 1) "name"
         2) "id"
         3) "type"
         4) "string"
         5) "value"
         6) "id"
5) 1) "name"
   2) "field_value"
   3) "type"
   4) "block"
   5) "flags"
   6) 1) multiple
   7) "value"
   8) 1) 1) "name"
         2) "field"
         3) "type"
         4) "string"
         5) "value"
         6) "field"
      2) 1) "name"
         2) "value"
         3) "type"
         4) "string"
         5) "value"
         6) "value"
```
