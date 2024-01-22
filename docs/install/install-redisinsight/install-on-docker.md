---
Title: Install RedisInsight on Docker
date: 2024-01-15 10:00:00
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
2. If you want to persist your RedisInsight data, make sure that the user inside the container has the necessary permissions on the mounted volume (`/db` in the example below)

```bash
docker run -d --name redisinsight -p 5540:5540 redis/redisinsight:latest -v redisinsight:/db
```

Then, point your browser to [http://localhost:5540](http://localhost:5540).

RedisInsight also provides a health check endpoint at [http://localhost:5540/healthcheck/](http://localhost:5540/healthcheck/) to monitor the health of the running container.

If everything worked, you should see the following output in the terminal:

```
Starting webserver...
Visit http://0.0.0.0:5540 in your web browser.
Press CTRL-C to exit.
```

### Resolving permission errors

If the previous command returns a permissions error, ensure the directory you pass as a volume to the container has necessary permissions for the container to access it. Run the following command:

```bash
{chown -R 1001 redisinsight}
```

### Adding flags to the run command

You can use additional flags with the `docker run` command:

1. You can add the `-it` flag to see the logs and view the progress.
1. On Linux, you can add `--network host`. This makes it easy to work with redis running on your local machine.
1. To analyze RDB files stored in S3, you can add the access key and secret access key as environment variables using the `-e` flag.

    For example: `-e AWS_ACCESS_KEY=<aws access key> -e AWS_SECRET_KEY=<aws secret access key>`

