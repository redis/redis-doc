# Redis Internals documentation

Redis source code is not very big (just 20k lines of code for the 2.2 release) and we try hard to make it simple and easy to understand. However we have some documentation explaining selected parts of the Redis internals.

Redis dynamic strings
---

String is the basic building block of Redis types. 

Redis is a key-value store.
All Redis keys are strings and its also the simplest value type.

Lists, sets, sorted sets and hashes are other more complex value types and even
these are composed of strings.

[Hacking Strings](/topics/internals-sds) documents the Redis String implementation details.

Redis Virtual Memory
---

We have a document explaining [virtual memory implementation details](/topics/internals-vm), but warning: this document refers to the 2.0 VM implementation. 2.2 is different... and better.

Redis Event Library
---

Read [event library](/topics/internals-eventlib) to understand what an event library does and why its needed.

[Redis event library](/topics/internals-rediseventlib) documents the implementation details of the event library used by Redis.
