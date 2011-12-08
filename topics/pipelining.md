Request/Response protocols and RTT
===

Redis is a TCP server using the client-server model and what is called a
*Request/Response* protocol.

This means that usually a request consists of the following steps:

* A client sends a query to the server, and reads the server's response from the
  socket (usually in a blocking way).
* The server processes the command and sends the response back to the client.

So for instance a four commands sequence looks something like this:

   Client: INCR X
   Server: 1
   Client: INCR X
   Server: 2
   Client: INCR X
   Server: 3
   Client: INCR X
   Server: 4

Clients and Servers are connected via a network link. Such a link can be very
fast (a loopback interface) or very slow (a connection established over the
Internet with many hops between the two hosts.) Whatever the network latency
is, it takes some time for the packets to travel from the client to the server,
and back from the server to the client to carry the reply.

This time is called *RTT* (Round Trip Time). It is very easy to see how the RTT
can affect the performances when a client needs to perform many requests in a
row (for instance when adding many elements to the same list, or populating a
database with many keys). For instance if the RTT time is 250 milliseconds (for
example, in a case of a very slow link over the Internet), even if the server
is able to process 100k requests per second, we'll be able to process four
requests per second at maximum due to the RTT delay.

If the interface in use is a loopback one, the RTT is much shorter (for
instance my host reports 0,044 milliseconds RTT when pinging 127.0.0.1), but it
is still a lot if you need to perform many writes in a row.

Fortunately, there is a way to improve performance in these use cases.

Redis Pipelining
---

A server handling Request/Response protocol can be implemented in such a way
that it would process new requests even if a client have not read the old
responses yet. This way a client can send *multiple commands* to the server
while not waiting for the replies, and finally read all the replies in a single
step afterwards.

This technique is called pipelining, and it has been in wide use for many decades.
For instance, many POP3 protocol implementations already support this feature,
dramatically speeding up the process of downloading new emails from the server.

Redis supports pipelining since the very early days, so no mater what version you
are running, you can use pipelining with Redis right away. Here is an example
using the raw netcat utility:

    $ (echo -en "PING\r\nPING\r\nPING\r\n"; sleep 1) | nc localhost 6379
    +PONG
    +PONG
    +PONG

This time we are not paying the cost of an RTT for every call, and read the
reply once for all the three commands.

To be very explicit, with pipelining the order of operations for the very first
example would be the following:

   Client: INCR X
   Client: INCR X
   Client: INCR X
   Client: INCR X
   Server: 1
   Server: 2
   Server: 3
   Server: 4

**IMPORTANT NOTE**: when a client sends commands using pipelining, the server
is forced to queue the replies in its memory. So if you need to send a lot of
commands with pipelining it's better to send the commands in batches of a given
reasonable size. For instance, send 10000 commands, read the replies, send
another 10000 commands, and so forth. The speed will be nearly the same, but
the amount of memory additionally used by the server would be limited by the
size of the queue holding replies for those 10000 commands.

Some benchmarks
---

In the following benchmark we'll use the Redis Ruby client supporting
pipelining to test the speed improvement due to the usage of the pipelining:

    require 'rubygems'
    require 'redis'

    def bench(descr)
        start = Time.now
        yield
        puts "#{descr} #{Time.now-start} seconds"
    end

    def without_pipelining
        r = Redis.new
        10000.times {
            r.ping
        }
    end

    def with_pipelining
        r = Redis.new
        r.pipelined {
            10000.times {
                r.ping
            }
        }
    end

    bench("without pipelining") {
        without_pipelining
    }
    bench("with pipelining") {
        with_pipelining
    }

Running the above simple script on my local Mac OS X system over a loopback
interface where pipelining provides the smallest improvement as the RTT is
already pretty low produced the following output:

    without pipelining 1.185238 seconds
    with pipelining 0.250783 seconds

As you can see by using pipelining we improved the transfer rate by a factor of five.

Pipelining VS other multi-commands
---

Often we get requests about adding new commands performing multiple operations
in a single pass.  For instance there is no command to add multiple elements in
a set. You need to call `SADD` many times.

The thing is that by leveraging pipelining you can have performance near to the
one provided by a hypothetical `MSADD` command, while at the same time we avoid
bloating the Redis command set with too many commands. An additional advantage
is that the version written using just `SADD` calls is ready to be run in a
distributed environment (for instance on a Redis Cluster, that is in the process of
making) just by dropping the pipelining code.
