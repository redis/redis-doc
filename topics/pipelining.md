Request/Response protocols and RTT
===

Redis is a TCP server using the client-server model and what is called a *Request/Response* protocol.

This means that usually a request is accomplished with the following steps:

* The client sends a query to the server, and reads from the socket, usually in a blocking way, for the server response.
* The server processes the command and sends the response back to the server.

So for instance a four commands sequence is something like this:

 * *Client:* INCR X
 * *Server:* 1
 * *Client:* INCR X
 * *Server:* 2
 * *Client:* INCR X
 * *Server:* 3
 * *Client:* INCR X
 * *Server:* 4

Clients and Servers are connected via a networking link. Such a link can be very fast (a loopback interface) or very slow (a connection established over the internet with many hops between the two hosts). Whatever the network latency is, there is a time for the packets to travel from the client to the server, and back from the server to the client to carry the reply.

This time is called RTT (Round Trip Time). It is very easy to see how this can affect the performances when a client needs to perform many requests in a row (for instance adding many elements to the same list, or populating a database with many keys). For instance if the RTT time is 250 milliseconds (in the case of a very slow link over the internet), even if the server is able to process 100k requests per second, we'll be able to process at max four requests per second.

If the interface used is a loopback interface, the RTT is much shorter (for instance my host reports 0,044 milliseconds pinging 127.0.0.1), but it is still a lot if you need to perform many writes in a row.

Fortunately there is a way to improve this use cases.

Redis Pipelining
---

A Request/Response server can be implemented so that it is able to process new requests even if the client didn't already read the old responses. This way it is possible to send *multiple commands* to the server without waiting for the replies at all, and finally read the replies in a single step.

This is called pipelining, and is a technique widely in use since many decades. For instance many POP3 protocol implementations already supported this feature, dramatically speeding up the process of downloading new emails from the server.

Redis supports pipelining since the very early days, so whatever version you are running, you can use pipelining with Redis. This is an example using the raw netcat utility:

    $ (echo -en "PING\r\nPING\r\nPING\r\n"; sleep 1) | nc localhost 6379
    +PONG
    +PONG
    +PONG

This time we are not paying the cost of RTT for every call, but just one time for the three commands.

To be very explicit, with pipelining the order of operations of our very first example will be the following:

 * *Client:* INCR X
 * *Client:* INCR X
 * *Client:* INCR X
 * *Client:* INCR X
 * *Server:* 1
 * *Server:* 2
 * *Server:* 3
 * *Server:* 4

**IMPORTANT NOTE**: while the client sends commands using pipelining, the server will be forced to queue the replies, using memory. So if you need to send many many commands with pipelining it's better to send this commands up to a given reasonable number, for instance 10k commands, read the replies, and send again other 10k commands and so forth. The speed will be nearly the same, but the additional memory used will be at max the amount needed to queue the replies for this 10k commands.

Some benchmark
---

In the following benchmark we'll use the Redis Ruby client, supporting pipelining, to test the speed improvement due to pipelining:

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

Running the above simple script will provide this figures in my Mac OS X system, running over the loopback interface, where pipelining will provide the smallest improvement as the RTT is already pretty low:

    without pipelining 1.185238 seconds
    with pipelining 0.250783 seconds

As you can see using pipelining we improved the transfer by a factor of five.

Pipelining VS other multi-commands
---

Often we get requests about adding new commands performing multiple operations in a single pass.
For instance there is no command to add multiple elements in a set. You need calling many times [SADD](/commands/sadd).

With pipelining you can have performances near to an hypothetical MSADD command, but at the same time we'll avoid bloating the Redis command set with too many commands. An additional advantage is that the version written using just SADD will be ready for a distributed environment (for instance Redis Cluster, that is in the process of being developed) just dropping the pipelining code.
