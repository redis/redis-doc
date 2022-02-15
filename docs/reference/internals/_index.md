---
title: "Redis internals"
linkTitle: "Redis internals"
weight: 1
aliases:
  - /topics/internals
---

**The following Redis documents were written by the creator of Redis, Salvatore Sanfilippo, early in the development of Redis (c. 2010), and do not necessarily reflect the latest Redis implementation.**

Dynamic strings
---

The first Redis data type was the string. Here you can read about the [dynamic strings implementation](/docs/reference/internals/internals-sds).

Event library
---

The [event library docs](/docs/reference/internals/internals-rediseventlib) describe what an event library does, why it's needed, and how the event library was originally implemented in Redis.

Virtual memory (deprecated)
---

Virtual memory was deprecated in Redis 2.6, but you can still learn about the [original Redis virtual memory implementation](/docs/reference/internals/internals-vm).
