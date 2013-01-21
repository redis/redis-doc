# Protocol specification

The Redis protocol is a compromise between the following things:

* Simple to implement
* Fast to parse by a computer
* Easy enough to parse by a human

Networking layer
----------------

A client connects to a Redis server creating a TCP connection to the port 6379.
Every Redis command or data transmitted by the client and the server is
terminated by `\r\n` (CRLF).

Requests
--------

Redis accepts commands composed of different arguments.
Once a command is received, it is processed and a reply is sent back to the client.

The new unified request protocol
--------------------------------

The new unified protocol was introduced in Redis 1.2, but it became the
standard way for talking with the Redis server in Redis 2.0.
This is the protocol you should implement in your Redis client.

In the unified protocol all the arguments sent to the Redis server are binary
safe. This is the general form:

    *<number of arguments> CR LF
    $<number of bytes of argument 1> CR LF
    <argument data> CR LF
    ...
    $<number of bytes of argument N> CR LF
    <argument data> CR LF

See the following example:

    *3
    $3
    SET
    $5
    mykey
    $7
    myvalue

This is how the above command looks as a quoted string, so that it is possible
to see the exact value of every byte in the query, including newlines.

    "*3\r\n$3\r\nSET\r\n$5\r\nmykey\r\n$7\r\nmyvalue\r\n"

As you will see in a moment this format is also used in Redis replies. The
format used for the single argument `$6\r\nmydata\r\n` is called a **Bulk Reply**.

The unified request protocol is what Redis already uses in replies in order
to send list of items to clients, and is called a **Multi Bulk Reply**.
It is just the sum of `N` different Bulk Replies prefixed by a `*<argc>\r\n`
string where `<argc>` is the number of arguments (Bulk Replies) that
will follow.

Replies
-------

Redis will reply to commands with different kinds of replies. It is always
possible to detect the kind of reply from the first byte sent by the server:

* In a Status Reply the first byte of the reply is "+"
* In an Error Reply the first byte of the reply is "-"
* In an Integer Reply the first byte of the reply is ":"
* In a Bulk Reply the first byte of the reply is "$"
* In a Multi Bulk Reply the first byte of the reply s "`*`"

<a name="status-reply"></a>

Status reply
-----------------

A Status Reply (or: single line reply) is in the form of a single line string
starting with "+" terminated by "\r\n". For example:

    +OK

The client library should return everything after the "+", that is, the string
"OK" in this example.

Status replies are not binary safe and can't include newlines, and are usually
returned by commands that don't need to return data, but just some kind of
status. Status replies have very little overhead of three bytes (the initial
"+" and the final CRLF).

Error reply
-----------

Error Replies are very similar to Status Replies. The only difference is that
the first byte is "-" instead of "+".

Error replies are only sent when something wrong happened, for instance if
you try to perform an operation against the wrong data type, or if the command
does not exist and so forth. So an exception should be raised by the library
client when an Error Reply is received.

<a name="integer-reply"></a>

A few examples of an error replies are the following:

    -ERR unknown command 'foobar'
    -WRONGTYPE Operation against a key holding the wrong kind of value

The first word after the "-", up to the first space or newline, represents
the kind of error returned.

`ERR` is the generic error, while `WRONGTYPE` is a more specific error.
A client implementation may return different kind of exceptions for different
errors, or may provide a generic way to trap errors by directly providing
the error name to the caller as a string.

However such a feature should not be considered vital as it is rarely useful, and a limited client implementation may simply return a generic error conditon, such as `false`.

Integer reply
-------------

This type of reply is just a CRLF terminated string representing an integer,
prefixed by a ":" byte. For example ":0\r\n", or ":1000\r\n" are integer
replies.

Examples of commands returning an integer are `INCR` and `LASTSAVE`.
There is no special meaning for the returned integer, it is just an
incremental number for `INCR`, a UNIX time for `LASTSAVE` and so forth, however
the returned integer is guaranteed to be in the range of a signed 64 bit
integer.

Integer replies are also extensively used in order to return true or false.
For instance commands like `EXISTS` or `SISMEMBER` will return 1 for true
and 0 for false.

Other commands like `SADD`, `SREM` and `SETNX` will return 1 if the operation
was actually performed, 0 otherwise.

The following commands will reply with an integer reply: `SETNX`, `DEL`,
`EXISTS`, `INCR`, `INCRBY`, `DECR`, `DECRBY`, `DBSIZE`, `LASTSAVE`,
`RENAMENX`, `MOVE`, `LLEN`, `SADD`, `SREM`, `SISMEMBER`, `SCARD`.

<a name="nil-reply"></a>
<a name="bulk-reply"></a>

Bulk replies
------------

Bulk replies are used by the server in order to return a single binary safe
string up to 512 MB in length.

    C: GET mykey
    S: $6\r\nfoobar\r\n

The server sends as the first line a "$" byte followed by the number of bytes
of the actual reply, followed by CRLF, then the actual data bytes are sent,
followed by additional two bytes for the final CRLF.  The exact sequence sent
by the server is:

    "$6\r\nfoobar\r\n"

If the requested value does not exist the bulk reply will use the special
value -1 as data length, example:

    C: GET nonexistingkey
    S: $-1

This is called a **NULL Bulk Reply**.

The client library API should not return an empty string, but a nil object,
when the requested object does not exist.  For example a Ruby library should
return 'nil' while a C library should return NULL (or set a special flag in the
reply object), and so forth.

<a name="multi-bulk-reply"></a>

Multi-bulk replies
------------------

Commands like `LRANGE` need to return multiple values (every element of a list
is a value, and `LRANGE` needs to return more than a single element). This is
accomplished using Multiple Bulk Replies.

A Multi bulk reply is used to return an array of other replies. Every element
of a Multi Bulk Reply can be of any kind, including a nested Multi Bulk Reply.

Multi Bulk Replies are sent using `*` as the first byte, followed by a string
representing the number of replies (elements of the array) that will follow,
followed by CR LF.

    C: LRANGE mylist 0 3
    S: *4
    S: $3
    S: foo
    S: $3
    S: bar
    S: $5
    S: Hello
    S: $5
    S: World

(Note: in the above example every string sent by the server has a trailing
CR LF newline).

As you can see the multi bulk reply is exactly the same format used in order
to send commands to the Redis server using the unified protocol. THe sole
differene is that while for the unified protocol only Bulk Replies are sent
as elements, with Multi Bulk Replies sent by the server as response to a
command every kind of reply type is valid as element of the Multi Bulk Reply.

For instance a list of four integers and a binary safe string can be sent as
a Multi Bulk Reply in the following format:

    *5\r\n
    :1\r\n
    :2\r\n
    :3\r\n
    :4\r\n
    $6\r\n
    foobar\r\n

The first line the server sent is `*5\r\n` in order to specify that five
replies will follow. Then every reply constituting the items of the
Multi Bulk reply is transmitted.

Empty Multi Bulk Reply are allowed, as in the following example:

    C: LRANGE nokey 0 1
    S: *0\r\n

Also the concept of Null Multi Bulk Reply exists.

For instance when the `BLPOP` command times out, it returns a Null Multi Bulk
Reply, that has a count of `-1` as in the following example:

    C: BLPOP key 1
    S: *-1\r\n

A client library API should return a null object and not an empty Array when
Redis replies with a Null Multi Bulk Reply. This is necessary to distinguish
between an empty list and a different condition (for instance the timeout
condition of the `BLPOP` command).

Null elements in Multi-Bulk replies
----------------------------------

Single elements of a multi bulk reply may have -1 length, in order to signal
that this elements are missing and not empty strings. This can happen with the
SORT command when used with the GET _pattern_ option when the specified key is
missing. Example of a multi bulk reply containing a null element:

    S: *3
    S: $3
    S: foo
    S: $-1
    S: $3
    S: bar

The second element is nul. The client library should return something like this:

    ["foo",nil,"bar"]

Note that this is not an exception to what said in the previous sections, but
just an example to further specify the protocol.

Multiple commands and pipelining
--------------------------------

A client can use the same connection in order to issue multiple commands.
Pipelining is supported so multiple commands can be sent with a single
write operation by the client, without the need to to read the server reply
of the previous command before issuing the next command.
All the replies can be read at the end.

Inline Commands
---------------

Sometimes you have only `telnet` in your hands and you need to send a command
to the Redis server. While the Redis protocol is simple to implement it is
not ideal to use in interactive sessions, and `redis-cli` may not always be
available. For this reason Redis also accepts commands in a special way that
is designed for humans, and is called the **inline command** format.

The following is an example of a server/client chat using an inline command
(the server chat starts with S:, the client chat with C:)

    C: PING
    S: +PONG

The following is another example of an inline command returning an integer:

    C: EXISTS somekey
    S: :0

Basically you simply write space-separated arguments in a telnet session.
Since no command starts with `*` that is instead used in the unified request
protocol, Redis is able to detect this condition and parse your command.
