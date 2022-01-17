# Command arguments

`COMMAND` returns information about Redis commands.
The last element of its reply is a map with additional fields, one of which is the `arguments` field.
It describes the arguments the command accepts.

The value of `arguments` is a list, where every element is a map with information about the argument.

This map's fields are:

 - `name`
 - `!type`
 - `key-spec-index`
 - `token`
 - `summary`
 - `since`
 - `flags`
 - `value`

Only `name` and `type` are mandatory. At least one of `value` or `token` must exist.

## name

The name of the argument (for identification purposes only, this value isn't displayed in the command's syntax).

## type

The type of the argument.

Possible argument types are:

 - `string`: a string argument
 - `integer`: an integer argument
 - `double`: a double-precision argument
 - `key`: a string that represents the name of a key
 - `pattern`: a string that is interpreted as a glob-like pattern
 - `unix-time`: an integer that represents a UNIX timestamp
 - `pure-token`: the argument is just a token, which may or not be specified (not free-text user input)
 - `oneof`: the argument is a container for nested arguments. This is used when there's a choice among several nested arguments (see example below).
 - `block`: the argument is a container for nested arguments. This is used for grouping arguments together and applying a property such as `optional` on all of them (see example below).

### Example

The trimming section of `XADD`, `[MAXLEN|MINID [=|~] threshold [LIMIT count]]` is a `block`, consisting of four sub-arguments:

1. trimming strategy: this nested argument is a `oneof`, with two nested arguments, each a `pure-token` (`MAXLEN` and `MINID`)
2. trimming operator: this nested argument is an optional `oneof`, with two nested arguments, each a `pure-token` (`=` and `~`)
3. threshold: this nested argument is a `string`
4. count: this nest argument is an optional `integer`, with a `token` (`LIMIT`)

## key-spec-index

When the command accepts arguments with type `key`, this field must exist and it holds the index of the corresponding `key-spec` within the `key-specs` array, returned by `COMMAND`.

For more information please check the [key-specs page][tr].
[tr]: /topics/key-specs

## token

Some arguments have a constant literal preceding the user's input (unless it's a `pure-token`, in which case there's no free-text user input).

## summary

A short description of the argument.

## since

The debut Redis version of this argument.

## flags

An @array-reply of argument flags:

Possible flags are:

 - `optional`: the argument is optional (for example, the `!GET` in the `SET` command)
 - `multiple`: the argument can be repeated (such as the `key` with `DEL`)
 - `multiple-token`: the argument can be repeated with its preceding token (see the `GET pattern` of `SORT`)

## value

The value can be one of the following:

1. A string, in which case it is the placeholder for the user's input. This is used when displaying the command's syntax (along with `token`, if it exists); or
2. In case the argument's `!type` is either `oneof` or `block`, the value is n array of maps, where each represents a nested argument

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

