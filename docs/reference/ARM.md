---
title: "Redis on ARM"
linkTitle: "Redis on ARM"
weight: 1
description: >
    Exploring Redis on the ARM Computer Architecture
aliases:
    - /docs/reference/ARM
---

Both Redis 4 and Redis 5 versions supports the ARM processor in general, and
the Raspberry Pi specifically, as a main platform, exactly like it happens
for Linux/x86. It means that every new release of Redis is tested on the Pi
environment, and that we take this documentation page updated with information
about supported devices and other useful info. While Redis already runs on
Android, in the future we look forward to extend our testing efforts to Android
to also make it an officially supported platform.

We believe that Redis is ideal for IoT and Embedded devices for several
reasons:

* Redis has a very small memory footprint and CPU requirements. It can run in small devices like the Raspberry Pi Zero without impacting the overall performance, using a small amount of memory, while delivering good performance for many use cases.
* The data structures of Redis are often a good way to model IoT/embedded use cases. For example in order to accumulate time series data, to receive or queue commands to execute or responses to send back to the remote servers and so forth.
* Modeling data inside Redis can be very useful in order to make in-device decisions for appliances that must respond very quickly or when the remote servers are offline.
* Redis can be used as an interprocess communication system between the processes running in the device.
* The append only file storage of Redis is well suited for the SSD cards.
* The Redis 5 stream data structure was specifically designed for time series applications and has a very low memory overhead.

## Redis /proc/cpu/alignment requirements

Linux on ARM allows to trap unaligned accesses and fix them inside the kernel
in order to continue the execution of the offending program instead of
generating a SIGBUS. Redis 4.0 and greater are fixed in order to avoid any kind
of unaligned access, so there is no need to have a specific value for this
kernel configuration. Even when kernel alignment fixing is disabled Redis should
run as expected.

## Building Redis in the Pi

* Download Redis version 4 or 5.
* Just use `make` as usual to create the executable.

There is nothing special in the process. The only difference is that by
default, Redis uses the libc allocator instead of defaulting to Jemalloc
as it does in other Linux based environments. This is because we believe
that for the small use cases inside embedded devices, memory fragmentation
is unlikely to be a problem. Moreover Jemalloc on ARM may not be as tested
as the libc allocator.

## Performance

Performance testing of Redis was performed in the Raspberry Pi 3 and in the
original model B Pi. The difference between the two Pis in terms of
delivered performance is quite big. The benchmarks were performed via the
loopback interface, since most use cases will probably use Redis from within
the device and not via the network. The following numbers were obtained using
Redis 4.

Raspberry Pi 3:

* Test 1 : 5 millions writes with 1 million keys (even distribution among keys).  No persistence, no pipelining. 28,000 ops/sec.
* Test 2: Like test 1 but with pipelining using groups of 8 operations: 80,000 ops/sec.
* Test 3: Like test 1 but with AOF enabled, fsync 1 sec: 23,000 ops/sec
* Test 4: Like test 3, but with an AOF rewrite in progress: 21,000 ops/sec

Raspberry Pi 1 model B:

* Test 1 : 5 millions writes with 1 million keys (even distribution among keys).  No persistence, no pipelining.  2,200 ops/sec.
* Test 2: Like test 1 but with pipelining using groups of 8 operations: 8,500 ops/sec.
* Test 3: Like test 1 but with AOF enabled, fsync 1 sec: 1,820 ops/sec
* Test 4: Like test 3, but with an AOF rewrite in progress: 1,000 ops/sec

The benchmarks above are referring to simple SET/GET operations. The performance is similar for all the Redis fast operations (not running in linear time). However sorted sets may show slightly slower numbers.
