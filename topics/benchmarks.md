# How fast is Redis?

Redis includes the `redis-benchmark` utility that simulates SETs/GETs done by N
clients at the same time sending M total queries (it is similar to the Apache's
`ab` utility). Below you'll find the full output of a benchmark executed
against a Linux box.

The following options are supported:

    Usage: redis-benchmark [-h <host>] [-p <port>] [-c <clients>] [-n <requests]> [-k <boolean>]

     -h <hostname>      Server hostname (default 127.0.0.1)
     -p <port>          Server port (default 6379)
     -s <socket>        Server socket (overrides host and port)
     -c <clients>       Number of parallel connections (default 50)
     -n <requests>      Total number of requests (default 10000)
     -d <size>          Data size of SET/GET value in bytes (default 2)
     -k <boolean>       1=keep alive 0=reconnect (default 1)
     -r <keyspacelen>   Use random keys for SET/GET/INCR, random values for SADD
      Using this option the benchmark will get/set keys
      in the form mykey_rand000000012456 instead of constant
      keys, the <keyspacelen> argument determines the max
      number of values for the random number. For instance
      if set to 10 only rand000000000000 - rand000000000009
      range will be allowed.
     -q                 Quiet. Just show query/sec values
     -l                 Loop. Run the tests forever
     -I                 Idle mode. Just open N idle connections and wait.

You need to have a running Redis instance before launching the benchmark.
A typical example would be:

    redis-benchmark -q -n 100000

Using this tool is quite easy, and you can also write your own benchmark,
but as with any benchmarking activity, there are some pitfalls to avoid.

Pitfalls and misconceptions
---------------------------

The first point is obvious: the golden rule of a useful benchmark is to
only compare apples and apples. Different versions of Redis can be compared
on the same workload for instance. Or the same version of Redis, but with
different options. If you plan to compare Redis to something else, then it is
important to evaluate the functional and technical differences, and take them
in account.

+ Redis is a server: all commands involve network or IPC roundtrips. It is
meaningless to compare it to embedded data stores such as SQLite, Berkeley DB,
Tokyo/Kyoto Cabinet, etc ... because the cost of most operations is precisely
dominated by network/protocol management.
+ Redis commands return an acknowledgment for all usual commands. Some other
data stores do not (for instance MongoDB does not implicitly acknowledge write
operations). Comparing Redis to stores involving one-way queries is only
mildly useful.
+ Naively iterating on synchronous Redis commands does not benchmark Redis
itself, but rather measure your network (or IPC) latency. To really test Redis,
you need multiple connections (like redis-benchmark) and/or use pipelining
to aggregate several commands.
+ Redis is an in-memory data store with some optional persistency options. If
you plan to compare it to transactional servers (MySQL, PostgreSQL, etc ...),
then you should consider activating AOF and decide of a suitable fsync policy.
+ Redis is a single-threaded server. It is not designed to benefit from
multiple CPU cores. People are supposed to launch several Redis instances to
scale out on several cores if needed. It is not really fair to compare one
single Redis instance to a multi-threaded data store.

Then the benchmark should do the same operations, and work in the same way with
the multiple data stores you want to compare. It is absolutely pointless to
compare the result of redis-benchmark to the result of another benchmark
program and extrapolate.

A common misconception is that redis-benchmark is designed to make Redis
performances look stellar, the throughput achieved by redis-benchmark being
somewhat artificial, and not achievable by a real application. This is
actually plain wrong.

The redis-benchmark program is a quick and useful way to get some figures and
evaluate the performance of a Redis instance on a given hardware. However,
it does not represent the maximum throughput a Redis instance can sustain.
Actually, by using pipelining and a fast client (hiredis), it is fairly easy
to write a program generating more throughput than redis-benchmark. The current
version of redis-benchmark achieves throughput only by parallelizing
connections. It does not use pipelining at all.

For instance, Redis and memcached in single-threaded mode can be compared on
GET/SET operations. Both are in-memory data stores, working mostly in the same
way at the protocol level. Provided their respective benchmark application is
aggregating queries in the same way (pipelining) and use a similar number of
connections, the comparison is actually meaningful.

This perfect example is illustrated by the dialog between Redis (antirez) and
memcached (dormando) developers.

You can see that in the end, the difference between the two solutions is not
so staggering.

Finally, when very efficient servers are benchmarked (and stores like Redis
or memcached definitely fall in this category), it may be difficult to saturate
the server. Sometimes, the performance bottleneck is on client side,
and not server-side. In that case, the client (i.e. the benchmark program itself)
must be fixed, or perhaps scaled out, in order to reach the maximum throughput.

Factors impacting Redis performance
-----------------------------------

There are multiple factors that can impact the result of a Redis benchmark.

+ Network bandwidth and latency usually have a direct impact on the performance.
It is a good practice to use the ping program to quickly check the latency
between the client and server hosts is normal before launching the benchmark.
Regarding the bandwidth, it is generally useful to estimate
the throughput in Gbits/s and compare it to the theoretical bandwidth
of the network. For instance a benchmark setting 4 KB strings
in Redis at 100000 q/s, would actually consume 3.2 Gbits/s of bandwidth
and probably fit with a 10 GBits/s link, but not a 1 Gbits/s one. In many real
world scenarios, Redis throughput is limited by the network well before being
limited by the CPU.
+ CPU is another very important factor. Being single-threaded, Redis favors
fast CPUs with large caches and not many cores. At this game, Intel CPUs are
currently the winners. It is not uncommon to get only half the performance on
an AMD Opteron CPU compared to similar Nehalem EP/Westmere EP/Sandy bridge
Intel CPUs with Redis. When client and server run on the same box, the CPU is
the limiting factor with redis-benchmark.
+ Redis runs slower on a VM. Virtualization toll is quite high because
for many common operations, Redis does not add much overhead on top of the
required system calls and network interruptions. Prefer to run Redis on a
physical box, especially if you favor deterministic latencies. On a
state-of-the-art hypervisor (VMWare), result of redis-benchmark on a VM
through the physical network is almost divided by 2 compared to the
physical machine, with some significant CPU time spent in system and
interruptions.
+ When the server and client benchmark programs run on the same box, both
the TCP/IP loopback and unix domain sockets can be used. It depends on the
platform, but unix domain sockets can achieve around 50% more throughput than
the TCP/IP loopback (on Linux for instance). The default behavior of
redis-benchmark is to use the TCP/IP loopback.
+ On multi CPU sockets servers, Redis performance becomes dependant on the
NUMA configuration and process location. The most visible effect is that
redis-benchmark results seem non deterministic because client and server
processes are distributed randomly on the cores. To get deterministic results,
it is required to use process placement tools (on Linux: taskset or numactl).
Here are some results of the SET benchmark for 3 CPUs (AMD Istanbul, Intel
Nehalem EX, and Intel Westmere) with different relative placement. The most
efficient combination is always to put the client and server on two different
cores of the same CPU to benefit from the L3 cache.

![NUMA chart](/dspezia/redis-doc/blob/system_info/topics/NUMA_chart.gif)

+ Management of interruptions and NIC configuration

Other things to consider
------------------------

- Fixed CPU frequency policy
- isolated environment as far as possible
- check the system: no swapping, no other I/O activity than the one of Redis etc ...
- 32/64 bits and memory consumption







# Example of benchmark result

* The test was done with 50 simultaneous clients performing 100000 requests.
* The value SET and GET is a 256 bytes string.
* The Linux box is running *Linux 2.6*, it's *Xeon X3320 2.5 GHz*.
* Text executed using the loopback interface (127.0.0.1).

Results: *about 110000 SETs per second, about 81000 GETs per second.*

## Latency percentiles

    $ redis-benchmark -n 100000

    ====== SET ======
      100007 requests completed in 0.88 seconds
      50 parallel clients
      3 bytes payload
      keep alive: 1

    58.50% <= 0 milliseconds
    99.17% <= 1 milliseconds
    99.58% <= 2 milliseconds
    99.85% <= 3 milliseconds
    99.90% <= 6 milliseconds
    100.00% <= 9 milliseconds
    114293.71 requests per second

    ====== GET ======
      100000 requests completed in 1.23 seconds
      50 parallel clients
      3 bytes payload
      keep alive: 1

    43.12% <= 0 milliseconds
    96.82% <= 1 milliseconds
    98.62% <= 2 milliseconds
    100.00% <= 3 milliseconds
    81234.77 requests per second

    ====== INCR ======
      100018 requests completed in 1.46 seconds
      50 parallel clients
      3 bytes payload
      keep alive: 1

    32.32% <= 0 milliseconds
    96.67% <= 1 milliseconds
    99.14% <= 2 milliseconds
    99.83% <= 3 milliseconds
    99.88% <= 4 milliseconds
    99.89% <= 5 milliseconds
    99.96% <= 9 milliseconds
    100.00% <= 18 milliseconds
    68458.59 requests per second

    ====== LPUSH ======
      100004 requests completed in 1.14 seconds
      50 parallel clients
      3 bytes payload
      keep alive: 1

    62.27% <= 0 milliseconds
    99.74% <= 1 milliseconds
    99.85% <= 2 milliseconds
    99.86% <= 3 milliseconds
    99.89% <= 5 milliseconds
    99.93% <= 7 milliseconds
    99.96% <= 9 milliseconds
    100.00% <= 22 milliseconds
    100.00% <= 208 milliseconds
    88109.25 requests per second

    ====== LPOP ======
      100001 requests completed in 1.39 seconds
      50 parallel clients
      3 bytes payload
      keep alive: 1

    54.83% <= 0 milliseconds
    97.34% <= 1 milliseconds
    99.95% <= 2 milliseconds
    99.96% <= 3 milliseconds
    99.96% <= 4 milliseconds
    100.00% <= 9 milliseconds
    100.00% <= 208 milliseconds
    71994.96 requests per second

Notes: changing the payload from 256 to 1024 or 4096 bytes does not change the
numbers significantly (but reply packets are glued together up to 1024 bytes so
GETs may be slower with big payloads). The same for the number of clients, from
50 to 256 clients I got the same numbers. With only 10 clients it starts to get
a bit slower.

You can expect different results from different boxes. For example a low
profile box like *Intel core duo T5500 clocked at 1.66 GHz running Linux 2.6*
will output the following:

    $ ./redis-benchmark -q -n 100000
    SET: 53684.38 requests per second
    GET: 45497.73 requests per second
    INCR: 39370.47 requests per second
    LPUSH: 34803.41 requests per second
    LPOP: 37367.20 requests per second

Another one using a 64 bit box, a Xeon L5420 clocked at 2.5 GHz:

    $ ./redis-benchmark -q -n 100000
    PING: 111731.84 requests per second
    SET: 108114.59 requests per second
    GET: 98717.67 requests per second
    INCR: 95241.91 requests per second
    LPUSH: 104712.05 requests per second
    LPOP: 93722.59 requests per second

