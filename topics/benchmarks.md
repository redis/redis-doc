# How fast is Redis?

Redis includes the `redis-benchmark` utility that simulates SETs/GETs done by N
clients at the same time sending M total queries (it is similar to the Apache's
`ab` utility). Below you'll find the full output of the benchmark executed
against a Linux box.

* The test was done with 50 simultaneous clients performing 100000 requests.
* The value SET and GET is a 256 bytes string.
* The Linux box is running *Linux 2.6*, it's *Xeon X3320 2.5Ghz*.
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
profile box like *Intel core duo T5500 clocked at 1.66Ghz running Linux 2.6*
will output the following:

    $ ./redis-benchmark -q -n 100000
    SET: 53684.38 requests per second
    GET: 45497.73 requests per second
    INCR: 39370.47 requests per second
    LPUSH: 34803.41 requests per second
    LPOP: 37367.20 requests per second

Another one using a 64 bit box, a Xeon L5420 clocked at 2.5 Ghz:

    $ ./redis-benchmark -q -n 100000
    PING: 111731.84 requests per second
    SET: 108114.59 requests per second
    GET: 98717.67 requests per second
    INCR: 95241.91 requests per second
    LPUSH: 104712.05 requests per second
    LPOP: 93722.59 requests per second

