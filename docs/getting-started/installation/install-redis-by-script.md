---
title: "Install Redis by Script"
linkTitle: "Install by Script"
weight: 5
description: >
    Install redis by script
---

To install Redis by script, run following:

{{< highlight bash >}}
wget https://raw.githubusercontent.com/Justman10000/redis/main/redis
mv redis /usr/bin
chmod -R 755 /usr/bin/redis
redis
{{< / highlight >}}

Then answer with *setup* then with the directory, where redis should be installed...