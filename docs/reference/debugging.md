---
title: "Debugging Redis"
linkTitle: "Debugging Redis"
weight: 1
description: >
    Redis debugging guide
aliases:
    - /topics/debugging
---

Redis is developed with a great stress on stability. We do our best with
every release to make sure you'll experience a very stable product and no
crashes. However even with our best efforts it is impossible to avoid all
the critical bugs with 100% success.

When Redis crashes it produces a detailed report of what happened, however
sometimes looking at the crash report is not enough, nor is it possible for
the Redis core team to reproduce the issue independently. In this scenario we
need help from the user that is able to reproduce the issue.

This little guide shows how to use GDB to provide all the information the
Redis developers will need to track the bug more easily.

## What is GDB?

GDB is the Gnu Debugger: a program that is able to inspect the internal state
of another program. Usually tracking and fixing a bug is an exercise in
gathering more information about the state of the program at the moment the
bug happens, so GDB is an extremely useful tool.

GDB can be used in two ways:

* It can attach to a running program and inspect the state of it at runtime.
* It can inspect the state of a program that already terminated using what is called a *core file*, that is, the image of the memory at the time the program was running.

From the point of view of investigating Redis bugs we need to use both of these
GDB modes. The user able to reproduce the bug attaches GDB to their running Redis
instance, and when the crash happens, they create the `core` file that in turn
the developer will use to inspect the Redis internals at the time of the crash.

This way the developer can perform all the inspections in his or her computer
without the help of the user, and the user is free to restart Redis in their
production environment.

## Compiling Redis without optimizations

By default Redis is compiled with the `-O2` switch, this means that compiler
optimizations are enabled. This makes the Redis executable faster, but at the
same time it makes Redis (like any other program) harder to inspect using GDB.

It is better to attach GDB to Redis compiled without optimizations using the
`make noopt` command (instead of just using the plain `make` command). However,
if you have an already running Redis in production there is no need to recompile
and restart it if this is going to create problems on your side. GDB still works
against executables compiled with optimizations.

You should not be overly concerned at the loss of performance from compiling Redis
without optimizations. It is unlikely that this will cause problems in your
environment as Redis is not very CPU-bound.

## Attaching GDB to a running process

If you have an already running Redis server, you can attach GDB to it, so that
if Redis crashes it will be possible to both inspect the internals and generate
a `core dump` file.

After you attach GDB to the Redis process it will continue running as usual without
any loss of performance, so this is not a dangerous procedure.

In order to attach GDB the first thing you need is the *process ID* of the running
Redis instance (the *pid* of the process). You can easily obtain it using
`redis-cli`:

    $ redis-cli info | grep process_id
    process_id:58414

In the above example the process ID is **58414**.

Login into your Redis server.

(Optional but recommended) Start **screen** or **tmux** or any other program that will make sure that your GDB session will not be closed if your ssh connection times out. You can learn more about screen in [this article](http://www.linuxjournal.com/article/6340).

Attach GDB to the running Redis server by typing:

    $ gdb <path-to-redis-executable> <pid>

For example:

    $ gdb /usr/local/bin/redis-server 58414

GDB will start and will attach to the running server printing something like the following:

    Reading symbols for shared libraries + done
    0x00007fff8d4797e6 in epoll_wait ()
    (gdb)

At this point GDB is attached but **your Redis instance is blocked by GDB**. In
order to let the Redis instance continue the execution just type **continue** at
the GDB prompt, and press enter.

    (gdb) continue
    Continuing.

Done! Now your Redis instance has GDB attached. Now you can wait for the next crash. :)

Now it's time to detach your screen/tmux session, if you are running GDB using it, by
pressing **Ctrl-a a** key combination.

## After the crash

Redis has a command to simulate a segmentation fault (in other words a bad crash) using
the `DEBUG SEGFAULT` command (don't use it against a real production instance of course!
So I'll use this command to crash my instance to show what happens in the GDB side:

    (gdb) continue
    Continuing.

    Program received signal EXC_BAD_ACCESS, Could not access memory.
    Reason: KERN_INVALID_ADDRESS at address: 0xffffffffffffffff
    debugCommand (c=0x7ffc32005000) at debug.c:220
    220         *((char*)-1) = 'x';

As you can see GDB detected that Redis crashed, and was even able to show me
the file name and line number causing the crash. This is already much better
than the Redis crash report back trace (containing just function names and
binary offsets).

## Obtaining the stack trace

The first thing to do is to obtain a full stack trace with GDB. This is as
simple as using the **bt** command:

    (gdb) bt
    #0  debugCommand (c=0x7ffc32005000) at debug.c:220
    #1  0x000000010d246d63 in call (c=0x7ffc32005000) at redis.c:1163
    #2  0x000000010d247290 in processCommand (c=0x7ffc32005000) at redis.c:1305
    #3  0x000000010d251660 in processInputBuffer (c=0x7ffc32005000) at networking.c:959
    #4  0x000000010d251872 in readQueryFromClient (el=0x0, fd=5, privdata=0x7fff76f1c0b0, mask=220924512) at networking.c:1021
    #5  0x000000010d243523 in aeProcessEvents (eventLoop=0x7fff6ce408d0, flags=220829559) at ae.c:352
    #6  0x000000010d24373b in aeMain (eventLoop=0x10d429ef0) at ae.c:397
    #7  0x000000010d2494ff in main (argc=1, argv=0x10d2b2900) at redis.c:2046

This shows the backtrace, but we also want to dump the processor registers using the **info registers** command:

    (gdb) info registers
    rax            0x0  0
    rbx            0x7ffc32005000   140721147367424
    rcx            0x10d2b0a60  4515891808
    rdx            0x7fff76f1c0b0   140735188943024
    rsi            0x10d299777  4515796855
    rdi            0x0  0
    rbp            0x7fff6ce40730   0x7fff6ce40730
    rsp            0x7fff6ce40650   0x7fff6ce40650
    r8             0x4f26b3f7   1327936503
    r9             0x7fff6ce40718   140735020271384
    r10            0x81 129
    r11            0x10d430398  4517462936
    r12            0x4b7c04f8babc0  1327936503000000
    r13            0x10d3350a0  4516434080
    r14            0x10d42d9f0  4517452272
    r15            0x10d430398  4517462936
    rip            0x10d26cfd4  0x10d26cfd4 <debugCommand+68>
    eflags         0x10246  66118
    cs             0x2b 43
    ss             0x0  0
    ds             0x0  0
    es             0x0  0
    fs             0x0  0
    gs             0x0  0

Please **make sure to include** both of these outputs in your bug report.

## Obtaining the core file

The next step is to generate the core dump, that is the image of the memory of the running Redis process. This is done using the `gcore` command:

    (gdb) gcore
    Saved corefile core.58414

Now you have the core dump to send to the Redis developer, but **it is important
to understand** that this happens to contain all the data that was inside the
Redis instance at the time of the crash; Redis developers will make sure not to
share the content with anyone else, and will delete the file as soon as it is no
longer used for debugging purposes, but you are warned that by sending the core
file you are sending your data.

## What to send to developers

Finally you can send everything to the Redis core team:

* The Redis executable you are using.
* The stack trace produced by the **bt** command, and the registers dump.
* The core file you generated with gdb.
* Information about the operating system and GCC version, and Redis version you are using.

## Thank you

Your help is extremely important! Many issues can only be tracked this way. So
thanks!
