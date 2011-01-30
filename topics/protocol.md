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
to see the exact value of every byte in the query:

    "*3\r\n$3\r\nSET\r\n$5\r\nmykey\r\n$8\r\nmyvalue\r\n"

As you will see in a moment this format is also used in Redis replies. The
format used for every argument `$6\r\nmydata\r\n` is called a Bulk Reply.
While the actual unified request protocol is what Redis uses to return list of
items, and is called a Multi Bulk Reply. It is just the sum of N different Bulk
Replies prefixed by a `*<argc>\r\n` string where `<argc>` is the number of
arguments (Bulk Replies) that will follow.

Replies
-------

Redis will reply to commands with different kinds of replies. It is possible to
check the kind of reply from the first byte sent by the server:

* With a single line reply the first byte of the reply will be "+"
* With an error message the first byte of the reply will be "-"
* With an integer number the first byte of the reply will be ":"
* With bulk reply the first byte of the reply will be "$"
* With multi-bulk reply the first byte of the reply will be "`*`"

<a name="status-reply"></a>

Single line reply
-----------------

A single line reply is in the form of a single line string
starting with "+" terminated by "\r\n". For example:

    +OK

The client library should return everything after the "+", that is, the string
"OK" in the example.

The following commands reply with a single line reply:
PING, SET, SELECT, SAVE, BGSAVE, SHUTDOWN, RENAME, LPUSH, RPUSH, LSET, LTRIM

Error reply
-----------

Errors are sent exactly like Single Line Replies. The only difference is that
the first byte is "-" instead of "+".

Error replies are only sent when something strange happened, for instance if
you try to perform an operation against the wrong data type, or if the command
does not exist and so forth. So an exception should be raised by the library
client when an Error Reply is received.

<a name="integer-reply"></a>

Integer reply
-------------

This type of reply is just a CRLF terminated string representing an integer,
prefixed by a ":" byte. For example ":0\r\n", or ":1000\r\n" are integer
replies.

With commands like INCR or LASTSAVE using the integer reply to actually return
a value there is no special meaning for the returned integer. It is just an
incremental number for INCR, a UNIX time for LASTSAVE and so on.

Some commands like EXISTS will return 1 for true and 0 for false.

Other commands like SADD, SREM and SETNX will return 1 if the operation was
actually done, 0 otherwise.

The following commands will reply with an integer reply: SETNX, DEL, EXISTS,
INCR, INCRBY, DECR, DECRBY, DBSIZE, LASTSAVE, RENAMENX, MOVE, LLEN, SADD, SREM,
SISMEMBER, SCARD

<a name="nil-reply"></a>
<a name="bulk-reply"></a>

Bulk replies
------------

Bulk replies are used by the server in order to return a single binary safe
string.

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

The client library API should not return an empty string, but a nil object,
when the requested object does not exist.  For example a Ruby library should
return 'nil' while a C library should return NULL (or set a special flag in the
reply object), and so forth.

<a name="multi-bulk-reply"></a>

Multi-bulk replies
------------------

Commands like LRANGE need to return multiple values (every element of the list
is a value, and LRANGE needs to return more than a single element). This is
accomplished using multiple bulk writes, prefixed by an initial line indicating
how many bulk writes will follow.  The first byte of a multi bulk reply is
always `*`. Example:

    C: LRANGE mylist 0 3
    s: *4
    s: $3
    s: foo
    s: $3
    s: bar
    s: $5
    s: Hello
    s: $5
    s: World

As you can see the multi bulk reply is exactly the same format used in order
to send commands to the Redis server unsing the unified protocol.

The first line the server sent is `*4\r\n` in order to specify that four bulk
replies will follow. Then every bulk write is transmitted.

If the specified key does not exist, the key is considered to hold an empty
list and the value `0` is sent as multi bulk count. Example:

    C: LRANGE nokey 0 1
    S: *0

When the `BLPOP` command times out, it returns the nil multi bulk reply. This
type of multi bulk has count `-1` and should be interpreted as a nil value.
Example:

    C: BLPOP key 1
    S: *-1

A client library API *SHOULD* return a nil object and not an empty list when this
happens. This is necessary to distinguish between an empty list and an error
condition (for instance the timeout condition of the `BLPOP` command).

Nil elements in Multi-Bulk replies
----------------------------------

Single elements of a multi bulk reply may have -1 length, in order to signal
that this elements are missing and not empty strings. This can happen with the
SORT command when used with the GET _pattern_ option when the specified key is
missing. Example of a multi bulk reply containing an empty element:

    S: *3
    S: $3
    S: foo
    S: $-1
    S: $3
    S: bar

The second element is nul. The client library should return something like this:

    ["foo",nil,"bar"]

Multiple commands and pipelining
--------------------------------

A client can use the same connection in order to issue multiple commands.
Pipelining is supported so multiple commands can be sent with a single
write operation by the client, it is not needed to read the server reply
in order to issue the next command. All the replies can be read at the end.

Usually Redis server and client will have a very fast link so this is not
very important to support this feature in a client implementation, still
if an application needs to issue a very large number of commands in short
time to use pipelining can be much faster.

The old protocol for sending commands
-------------------------------------

Before of the Unified Request Protocol Redis used a different protocol to send
commands, that is still supported since it is simpler to type by hand via
telnet. In this protocol there are two kind of commands:

* Inline commands: simple commands where argumnets are just space separated
  strings. No binary safeness is possible.
* Bulk commands: bulk commands are exactly like inline commands, but the last
  argument is handled in a special way in order to allow for a binary-safe last
  argument.

Inline Commands
---------------

The simplest way to send Redis a command is via **inline commands**. The
following is an example of a server/client chat using an inline command (the
server chat starts with S:, the client chat with C:)

    C: PING
    S: +PONG

The following is another example of an INLINE command returning an integer:

    C: EXISTS somekey
    S: :0

Since 'somekey' does not exist the server returned ':0'.

Note that the EXISTS command takes one argument. Arguments are separated
by spaces.

Bulk commands
-------------

Some commands when sent as inline commands require a special form in order to
support a binary safe last argument. This commands will use the last argument
for a "byte count", then the bulk data is sent (that can be binary safe since
the server knows how many bytes to read).

See for instance the following example:

    C: SET mykey 6
    C: foobar
    S: +OK

The last argument of the commnad is '6'. This specify the number of DATA bytes
that will follow, that is, the string "foobar". Note that even this bytes are
terminated by two additional bytes of CRLF.

All the bulk commands are in this exact form: instead of the last argument the
number of bytes that will follow is specified, followed by the bytes composing
the argument itself, and CRLF. In order to be more clear for the programmer
this is the string sent by the client in the above sample:

    "SET mykey 6\r\nfoobar\r\n"

Redis has an internal list of what command is inline and what command is bulk,
so you have to send this commands accordingly. It is strongly suggested to use
the new Unified Request Protocol instead.

