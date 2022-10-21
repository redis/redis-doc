---
title: "Redis persistence"
linkTitle: "Redis persistence"
weight: 5
description: >
    Learn how Redis persistence works
aliases:
    - /docs/getting-started/redis-persistence
---

You can learn how Redis persistence works on [this page](/docs/manual/persistence), however what is important to understand for a quickstart is that, by default, if you start Redis with the default configuration, Redis will spontaneously save the dataset only from time to time (for instance after at least five minutes if you have at least 100 changes in your data), so if you want your database to persist and be reloaded after a restart make sure to call the **SAVE** command manually every time you want to force a data set snapshot. Otherwise, make sure to shutdown the database using the **SHUTDOWN** command:

    $ redis-cli shutdown

This way Redis will make sure to save the data on disk before quitting.
Reading the [persistence page](/docs/manual/persistence) is strongly suggested in order to better understand how Redis persistence works.