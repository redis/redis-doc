# Command arguments

`COMMAND` returns infromation about Redis commands.
The last element of its reply is a map with aditional fields, one of which
is the `arguments` field, which describes the arguments the command takes.

It is a list, where every element is a map with information about the argument.

These map fields are:
 - `name`
 - `type`
 - `key-spec-index`
 - `token`
 - `summary`
 - `since`
 - `flags`
 - `value`

Only `name` and `type` are mandatory. At least one of `value` or `token` must exist.

## name

The name of the argument (for for identification, not what's displayed in the command syntax)

## type

The type of the argument

The possible types are:
 - `string`: String argument
 - `integer`: Integer argument
 - `double`: Double-precision argument
 - `key`: String, but represents a key-name
 - `pattern`: String, but represents a regex pattern
 - `unix-time`: Integer, but represents a UNIX timestamp
 - `pure-token`: The argument is just a token, which can exist or not (not a free-text input from user)
 - `oneof`: The argument is a container of sub-arguments. Used when user can choose only one of a few sub-arguments (see example below)
 - `block`: The argument is a container of sub-arguments. Used when one wants to group together several sub-arguments, usually to apply something onall of them (like making the entire group "optional") (see example below)

### Example

The trimming section of `XADD`, `[MAXLEN|MINID [=|~] threshold [LIMIT count]]` is a `block`, consisting of four sub-arguments:
1. trimming startegy: this sub-argument is a `oneof`, with two sub-sub-arguments, each a `pure-token` (`MAXLEN` and `MINID`)
2. trimming operator: this sub-argument is an optional `oneof`, with two sub-sub-arguments, each a `pure-token` (`=` and `~`)
3. threshold: this sub-argument is a `string`
4. count: this sub-argument is an optional `integer`, with a `token` (`LIMIT`)

## key-spec-index

If the command is of type `key` this fields must exist and it contains the index of the corresponding `key-spec` within the `key-specs` array, returned by `COMMAND`
For more information please check the [key-specs page][tr].
[tr]: /topics/key-specs

## token

Some arguments have a contant literal before the user input (unless it's a `pure-token`, in which case there's no free-text user input)

## summary

A short description of the argument

## since

The debut Redis version of this argument

## flags

Nested @array-reply of argument flags:

Possible flags are:
 - `optional`: Argument is optional (like `GET` in `SET` command)
 - `multiple`: Argument may be repeated (like `key` in `DEL`)
 - `multiple-token`: The argument may repeat itself, and so does its token (like `GET pattern` in `SORT`)

## value

Can be either:

1. A string, in which case it is the placeholder of a user input. Used to be displayed when building the command syntax (along with `token`, if exists); or
2. An array of maps, each representing a sub-argument (in case the `type` is `oneof` or `block`)

## Example

Here's the argument array of `XADD`:

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

