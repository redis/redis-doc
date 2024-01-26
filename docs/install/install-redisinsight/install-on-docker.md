---
Title: Install RedisInsight on Docker
date: 2024-01-30 10:00:00
weight: 30
categories: ["RI"]
path: install/install-redisinsight/install-on-docker/
altTag: Install RedisInsight on Docker
---
This tutorial shows how to install RedisInsight on [Docker](https://www.docker.com/) so you can use RedisInsight in development.
See a separate guide for installing [RedisInsight on AWS]({{< relref "/docs/install/install-on-aws.md" >}}).

## Install Docker

The first step is to [install Docker for your operating system](https://docs.docker.com/install/). 

## Run RedisInsight Docker image

Next, run the RedisInsight container.

1. If you do not want to persist your RedisInsight data.

```bash
docker run -d --name redisinsight -p 5540:5540 redis/redisinsight:latest
```
2. If you want to persist your RedisInsight data, attach docker volume to the `/data` path.
After the source directory is created, run the following command.

```bash
docker run -d --name redisinsight -p 5540:5540 redis/redisinsight:latest -v redisinsight:/data
```

If the previous command returns a permission error, ensure that the user with ID = 1000 has necessary permission to access the volume provided (`redisinsight` in the command above).


Then, point your browser to [http://localhost:5540](http://localhost:5540).

RedisInsight also provides a health check endpoint at http://localhost:5540/api/health/ to monitor the health of the running container.
