---
title: "RESP protocol spec"
linkTitle: "Protocol spec"
weight: 1
description: Redis serialization protocol (RESP) specification
aliases:
    - /topics/protocol
---

Redis clients use a protocol called **RESP** (REdis Serialization Protocol) to communicate with the Redis server. While the protocol was designed specifically for Redis, it can be used for other client-server software projects.

RESP is a compromise between the following things:

* Simple to implement.
* Fast to parse.
* Human readable.

RESP can serialize different data types like integers, strings, and arrays. There is also a specific type for errors. Requests are sent from the client to the Redis server as arrays of strings that represent the arguments of the command to execute. Redis replies with a command-specific data type.

RESP is binary-safe and does not require processing of bulk data transferred from one process to another because it uses prefixed-length to transfer bulk data.

Note: the protocol outlined here is only used for client-server communication. Redis Cluster uses a different binary protocol in order to exchange messages between nodes.

## Network layer

A client connects to a Redis server by creating a TCP connection to the port 6379.

While RESP is technically non-TCP specific, the protocol is only used with TCP connections (or equivalent stream-oriented connections like Unix sockets) in the context of Redis.

## Request-Response model

Redis accepts commands composed of different arguments.
Once a command is received, it is processed and a reply is sent back to the client.

This is the simplest model possible; however, there are two exceptions:

* Redis supports pipelining (covered later in this document). So it is possible for clients to send multiple commands at once and wait for replies later.
* When a Redis client subscribes to a Pub/Sub channel, the protocol changes semantics and becomes a *push* protocol. The client no longer requires sending commands because the server will automatically send new messages to the client (for the channels the client is subscribed to) as soon as they are received.

Excluding these two exceptions, the Redis protocol is a simple request-response protocol.

## RESP protocol description

The RESP protocol was introduced in Redis 1.2, but it became the
standard way for talking with the Redis server in Redis 2.0.
This is the protocol you should implement in your Redis client.

RESP is actually a serialization protocol that supports the following
data types: Simple Strings, Errors, Integers, Bulk Strings, and Arrays.

Redis uses RESP as a request-response protocol in the
following way:

* Clients send commands to a Redis server as a RESP Array of Bulk Strings.
* The server replies with one of the RESP types according to the command implementation.

In RESP, the first byte determines the data type:

* For **Simple Strings**, the first byte of the reply is "+"
* For **Errors**, the first byte of the reply is "-"
* For **Integers**, the first byte of the reply is ":"
* For **Bulk Strings**, the first byte of the reply is "$"
* For **Arrays**, the first byte of the reply is "`*`"

RESP can represent a Null value using a special variation of Bulk Strings or Array as specified later.

In RESP, different parts of the protocol are always terminated with "\r\n" (CRLF).

<a name="simple-string-reply"></a>

## RESP Simple Strings

Simple Strings are encoded as follows: a plus character, followed by a string that cannot contain a CR or LF character (no newlines are allowed), and terminated by CRLF (that is "\r\n").

Simple Strings are used to transmit non binary-safe strings with minimal overhead. For example, many Redis commands reply with just "OK" on success. The RESP Simple String is encoded with the following 5 bytes:

    "+OK\r\n"

In order to send binary-safe strings, use RESP Bulk Strings instead.

When Redis replies with a Simple String, a client library should respond with a string composed of the first character after the '+'
up to the end of the string, excluding the final CRLF bytes.

<a name="error-reply"></a>

## RESP Errors

RESP has a specific data type for errors. They are similar to
RESP Simple Strings, but the first character is a minus '-' character instead
of a plus. The real difference between Simple Strings and Errors in RESP is that clients treat errors
as exceptions, and the string that composes
the Error type is the error message itself.

The basic format is:

    "-Error message\r\n"

Error replies are only sent when something goes wrong, for instance if
you try to perform an operation against the wrong data type, or if the command
does not exist. The client should raise an exception when it receives an Error reply.

The following are examples of error replies:

    -ERR unknown command 'helloworld'
    -WRONGTYPE Operation against a key holding the wrong kind of value

The first word after the "-", up to the first space or newline, represents
the kind of error returned. This is just a convention used by Redis and is not
part of the RESP Error format.

For example, `ERR` is the generic error, while `WRONGTYPE` is a more specific
error that implies that the client tried to perform an operation against the
wrong data type. This is called an **Error Prefix** and is a way to allow
the client to understand the kind of error returned by the server without checking the exact error message.

A client implementation may return different types of exceptions for different
errors or provide a generic way to trap errors by directly providing
the error name to the caller as a string.

However, such a feature should not be considered vital as it is rarely useful, and a limited client implementation may simply return a generic error condition, such as `false`.

<a name="integer-reply"></a>

## RESP Integers

This type is just a CRLF-terminated string that represents an integer,
prefixed by a ":" byte. For example, ":0\r\n" and ":1000\r\n" are integer replies.

Many Redis commands return RESP Integers, like `INCR`, `LLEN`, and `LASTSAVE`.

There is no special meaning for the returned integer. It is just an
incremental number for `INCR`, a UNIX time for `LASTSAVE`, and so forth. However,
the returned integer is guaranteed to be in the range of a signed 64-bit integer.

Integer replies are also used in order to return true or false.
For instance, commands like `EXISTS` or `SISMEMBER` will return 1 for true
and 0 for false.

Other commands like `SADD`, `SREM`, and `SETNX` will return 1 if the operation
was actually performed and 0 otherwise.

The following commands will reply with an integer: `SETNX`, `DEL`,
`EXISTS`, `INCR`, `INCRBY`, `DECR`, `DECRBY`, `DBSIZE`, `LASTSAVE`,
`RENAMENX`, `MOVE`, `LLEN`, `SADD`, `SREM`, `SISMEMBER`, `SCARD`.

<a name="nil-reply"></a>
<a name="bulk-string-reply"></a>

## RESP Bulk Strings

Bulk Strings are used in order to represent a single binary-safe
string up to 512 MB in length.

Bulk Strings are encoded in the following way:

* A "$" byte followed by the number of bytes composing the string (a prefixed length), terminated by CRLF.
* The actual string data.
* A final CRLF.

So the string "hello" is encoded as follows:

    "$5\r\nhello\r\n"

An empty string is encoded as:

    "$0\r\n\r\n"

RESP Bulk Strings can also be used in order to signal non-existence of a value
using a special format to represent a Null value. In this
format, the length is -1, and there is no data. Null is represented as:

    "$-1\r\n"

This is called a **Null Bulk String**.

The client library API should not return an empty string, but a nil object,
when the server replies with a Null Bulk String.
For example, a Ruby library should return 'nil' while a C library should
return NULL (or set a special flag in the reply object).

<a name="array-reply"></a>

## RESP Arrays

Clients send commands to the Redis server using RESP Arrays. Similarly,
certain Redis commands, that return collections of elements to the client,
use RESP Arrays as their replies. An example is the `LRANGE` command that
returns elements of a list.

RESP Arrays are sent using the following format:

* A `*` character as the first byte, followed by the number of elements in the array as a decimal number, followed by CRLF.
* An additional RESP type for every element of the Array.

So an empty Array is just the following:

    "*0\r\n"

While an array of two RESP Bulk Strings "hello" and "world" is encoded as:

    "*2\r\n$3\r\nhello\r\n$3\r\nworld\r\n"

As you can see after the `*<count>CRLF` part prefixing the array, the other
data types composing the array are just concatenated one after the other.
For example, an Array of three integers is encoded as follows:

    "*3\r\n:1\r\n:2\r\n:3\r\n"

Arrays can contain mixed types, so it's not necessary for the
elements to be of the same type. For instance, a list of four
integers and a bulk string can be encoded as follows:

    *5\r\n
    :1\r\n
    :2\r\n
    :3\r\n
    :4\r\n
    $6\r\n
    hello\r\n

(The reply was split into multiple lines for clarity).

The first line the server sent is `*5\r\n` in order to specify that five
replies will follow. Then every reply constituting the items of the
Multi Bulk reply are transmitted.

Null Arrays exist as well and are an alternative way to
specify a Null value (usually the Null Bulk String is used, but for historical
reasons we have two formats).

For instance, when the `BLPOP` command times out, it returns a Null Array
that has a count of `-1` as in the following example:

    "*-1\r\n"

A client library API should return a null object and not an empty Array when
Redis replies with a Null Array. This is necessary to distinguish
between an empty list and a different condition (for instance the timeout
condition of the `BLPOP` command).

Nested arrays are possible in RESP. For example a nested array of two arrays
is encoded as follows:

    *2\r\n
    *3\r\n
    :1\r\n
    :2\r\n
    :3\r\n
    *2\r\n
    +Hello\r\n
    -World\r\n

(The format was split into multiple lines to make it easier to read).

The above RESP data type encodes a two-element Array consisting of an Array that contains three Integers (1, 2, 3) and an array of a Simple String and an Error.

## Null elements in Arrays

Single elements of an Array may be Null. This is used in Redis replies to signal that these elements are missing and not empty strings. This
can happen with the SORT command when used with the GET _pattern_ option
if the specified key is missing. Example of an Array reply containing a
Null element:

    *3\r\n
    $3\r\n
    hello\r\n
    $-1\r\n
    $3\r\n
    world\r\n

The second element is a Null. The client library should return something
like this:

    ["hello",nil,"world"]

Note that this is not an exception to what was said in the previous sections, but 
an example to further specify the protocol.

## Send commands to a Redis server

Now that you are familiar with the RESP serialization format, you can use it to help write a Redis client library. We can further specify
how the interaction between the client and the server works:

* A client sends the Redis server a RESP Array consisting of only Bulk Strings.
* A Redis server replies to clients, sending any valid RESP data type as a reply.

So for example a typical interaction could be the following.

The client sends the command **LLEN mylist** in order to get the length of the list stored at key *mylist*. Then the server replies with an Integer reply as in the following example (C: is the client, S: the server).

    C: *2\r\n
    C: $4\r\n
    C: LLEN\r\n
    C: $6\r\n
    C: mylist\r\n

    S: :48293\r\n

As usual, we separate different parts of the protocol with newlines for simplicity, but the actual interaction is the client sending `*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n` as a whole.

## Multiple commands and pipelining

A client can use the same connection in order to issue multiple commands.
Pipelining is supported so multiple commands can be sent with a single
write operation by the client, without the need to read the server reply
of the previous command before issuing the next one.
All the replies can be read at the end.

For more information, see [Pipelining](/topics/pipelining).

## Inline commands

Sometimes you may need to send a command
to the Redis server but only have `telnet` available. While the Redis protocol is simple to implement, it is
not ideal to use in interactive sessions, and `redis-cli` may not always be
available. For this reason, Redis also accepts commands in the **inline command** format.

The following is an example of a server/client chat using an inline command
(the server chat starts with S:, the client chat with C:)

    C: PING
    S: +PONG

The following is an example of an inline command that returns an integer:

    C: EXISTS somekey
    S: :0

Basically, you write space-separated arguments in a telnet session.
Since no command starts with `*` that is instead used in the unified request
protocol, Redis is able to detect this condition and parse your command.

## High performance parser for the Redis protocol

While the Redis protocol is human readable and easy to implement, it can
be implemented with a performance similar to that of a binary protocol.

RESP uses prefixed lengths to transfer bulk data, so there is
never a need to scan the payload for special characters, like with JSON, nor to quote the payload that needs to be sent to the
server.

The Bulk and Multi Bulk lengths can be processed with code that performs
a single operation per character while at the same time scanning for the
CR character, like the following C code:

```
#include <stdio.h>

int main(void) {
    unsigned char *p = "$123\r\n";
    int len = 0;

    p++;
    while(*p != '\r') {
        len = (len*10)+(*p - '0');
        p++;
    }

    /* Now p points at '\r', and the len is in bulk_len. */
    printf("%d\n", len);
    return 0;
}
```

After the first CR is identified, it can be skipped along with the following
LF without any processing. Then the bulk data can be read using a single
read operation that does not inspect the payload in any way. Finally,
the remaining CR and LF characters are discarded without any processing.

While comparable in performance to a binary protocol, the Redis protocol is
significantly simpler to implement in most high-level languages,
reducing the number of bugs in client software.
