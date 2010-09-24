Redis is an advanced key-value store. It is similar to memcached but
the dataset is not volatile. Values can be strings, exactly like
in memcached, but also lists, sets, and ordered sets. All this data
types can be manipulated with atomic operations to push/pop elements,
add/remove elements, perform server side union, intersection, difference
between sets, and so forth. Redis supports different kind of sorting
abilities.

In order to be very fast but at the same time persistent the whole
dataset is taken in memory, and from time to time saved on disk
asynchronously (semi persistent mode) or alternatively every change is
written into an [append-only file](/topics/append-only-file) (fully
persistent mode). Redis is able to rebuild the append-only file in
background when it gets too big.

Redis supports trivial to setup [master-slave
replication](/topics/replication), with very fast non-blocking first
synchronization, auto-reconnection on net split, and so forth.

Redis is written in ANSI C and works in most POSIX systems like Linux,
*BSD, Mac OS X, Solaris, and so on. Redis is free software released
under the very liberal BSD license. Redis is reported to compile and
work under WIN32 if compiled with Cygwin, but there is no official
support for Windows currently.
