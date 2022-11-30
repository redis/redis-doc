---
title: "Redis programmability"
linkTitle: "Programmability"
weight: 7
description: >
   Extending Redis with Lua and Redis Functions
aliases:
    - /topics/programmability
---

Redis provides a programming interface that lets you execute custom scripts on the server itself. In Redis 7 and beyond, you can use [Redis Functions](/docs/manual/programmability/functions-intro) to manage and run your scripts. In Redis 6.2 and below, you use [Lua scripting with the EVAL command](/docs/manual/programmability/eval-intro) to program the server.

## Background

Redis is, by [definition](https://github.com/redis/redis/blob/unstable/MANIFESTO#L7), a _"domain-specific language for abstract data types"_.
The language that Redis speaks consists of its [commands](/commands).
Most the commands specialize at manipulating core [data types](/topics/data-types-intro) in different ways.
In many cases, these commands provide all the functionality that a developer requires for managing application data in Redis.

The term **programmability** in Redis means having the ability to execute arbitrary user-defined logic by the server.
We refer to such pieces of logic as **scripts**.
In our case, scripts enable processing the data where it lives, a.k.a _data locality_.
Furthermore, the responsible embedding of programmatic workflows in the Redis server can help in reducing network traffic and improving overall performance.
Developers can use this capability for implementing robust, application-specific APIs.
Such APIs can encapsulate business logic and maintain a data model across multiple keys and different data structures.

User scripts are executed in Redis by an embedded, sandboxed scripting engine.
Presently, Redis supports a single scripting engine, the [Lua 5.1](https://www.lua.org/) interpreter.

Please refer to the [Redis Lua API Reference](/topics/lua-api) page for complete documentation.

## Running scripts

Redis provides two means for running scripts.

Firstly, and ever since Redis 2.6.0, the `EVAL` command enables running server-side scripts.
Eval scripts provide a quick and straightforward way to have Redis run your scripts ad-hoc.
However, using them means that the scripted logic is a part of your application (not an extension of the Redis server).
Every applicative instance that runs a script must have the script's source code readily available for loading at any time.
That is because scripts are only cached by the server and are volatile.
As your application grows, this approach can become harder to develop and maintain.

Secondly, added in v7.0, Redis Functions are essentially scripts that are first-class database elements.
As such, functions decouple scripting from application logic and enable independent development, testing, and deployment of scripts.
To use functions, they need to be loaded first, and then they are available for use by all connected clients.
In this case, loading a function to the database becomes an administrative deployment task (such as loading a Redis module, for example), which separates the script from the application.

Please refer to the following pages for more information:

* [Redis Eval Scripts](/topics/eval-intro)
* [Redis Functions](/topics/functions-intro)

When running a script or a function, Redis guarantees its atomic execution.
The script's execution blocks all server activities during its entire time, similarly to the semantics of [transactions](/topics/transactions).
These semantics mean that all of the script's effects either have yet to happen or had already happened.
The blocking semantics of an executed script apply to all connected clients at all times.

Note that the potential downside of this blocking approach is that executing slow scripts is not a good idea.
It is not hard to create fast scripts because scripting's overhead is very low.
However, if you intend to use a slow script in your application, be aware that all other clients are blocked and can't execute any command while it is running.

## Read-only scripts

A read-only script is a script that only executes commands that don't modify any keys within Redis.
Read-only scripts can be executed either by adding the `no-writes` [flag](/topics/lua-api#script_flags) to the script or by executing the script with one of the read-only script command variants: `EVAL_RO`, `EVALSHA_RO`, or `FCALL_RO`.
They have the following properties:

* They can always be executed on replicas.
* They can always be killed by the `SCRIPT KILL` command. 
* They never fail with OOM error when redis is over the memory limit.
* They are not blocked during write pauses, such as those that occur during coordinated failovers.
* They cannot execute any command that may modify the data set.
* Currently `PUBLISH`, `SPUBLISH` and `PFCOUNT` are also considered write commands in scripts, because they could attempt to propagate commands to replicas and AOF file.

In addition to the benefits provided by all read-only scripts, the read-only script commands have the following advantages:

* They can be used to configure an ACL user to only be able to execute read-only scripts.
* Many clients also better support routing the read-only script commands to replicas for applications that want to use replicas for read scaling.

#### Read-only script history

Read-only scripts and read-only script commands were introduced in Redis 7.0

* Before Redis 7.0.1 `PUBLISH`, `SPUBLISH` and `PFCOUNT` were not considered write commands in scripts
* Before Redis 7.0.1 the `no-writes` [flag](/topics/lua-api#script_flags) did not imply `allow-oom`
* Before Redis 7.0.1 the `no-writes` flag did not permit the script to run during write pauses.


The recommended approach is to use the standard scripting commands with the `no-writes` flag unless you need one of the previously mentioned features.

## Sandboxed script context

Redis places the engine that executes user scripts inside a sandbox.
The sandbox attempts to prevent accidental misuse and reduce potential threats from the server's environment.

Scripts should never try to access the Redis server's underlying host systems, such as the file system, network, or attempt to perform any other system call other than those supported by the API.

Scripts should operate solely on data stored in Redis and data provided as arguments to their execution.

## Maximum execution time

Scripts are subject to a maximum execution time (set by default to five seconds).
This default timeout is enormous since a script usually runs in less than a millisecond.
The limit is in place to handle accidental infinite loops created during development.

It is possible to modify the maximum time a script can be executed with millisecond precision,
either via `redis.conf` or by using the `CONFIG SET` command.
The configuration parameter affecting max execution time is called `busy-reply-threshold`.

When a script reaches the timeout threshold, it isn't terminated by Redis automatically.
Doing so would violate the contract between Redis and the scripting engine that ensures that scripts are atomic.
Interrupting the execution of a script has the potential of leaving the dataset with half-written changes.

Therefore, when a script executes longer than the configured timeout, the following happens:

* Redis logs that a script is running for too long.
* It starts accepting commands again from other clients but will reply with a BUSY error to all the clients sending normal commands. The only commands allowed in this state are `SCRIPT KILL`, `FUNCTION KILL`, and `SHUTDOWN NOSAVE`.
* It is possible to terminate a script that only executes read-only commands using the `SCRIPT KILL` and `FUNCTION KILL` commands. These commands do not violate the scripting semantic as no data was written to the dataset by the script yet.
* If the script had already performed even a single write operation, the only command allowed is `SHUTDOWN NOSAVE` that stops the server without saving the current data set on disk (basically, the server is aborted).
