---
Title: Configure RedisInsight
date: 2024-01-30 10:00:00
weight: 60
categories: ["RI"]
path: install/install-redisinsight/configuration
altTag: Configure RedisInsight
---
You can configure RedisInsight with system environment variables.

To configure RedisInsight with environment variables:

1. Set environment variables for your operating system:

    - [Mac](https://apple.stackexchange.com/a/106814)
    - [Windows](https://support.microsoft.com/en-au/topic/how-to-manage-environment-variables-in-windows-xp-5bf6725b-655e-151c-0b55-9a8c9c7f747d)
    - [Linux](https://askubuntu.com/a/58828)
    - [Docker](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)

1. Set the environment variables.
1. Restart RedisInsight.

## RedisInsight environment variables

The following environment variables can be set to configure RedisInsight:

| Environment variable | Description | Type | Default |
| --- | --- | --- | --- |
| RI_APP_PORT | Port which RedisInsight should listen to. | Number | `5540` |
| RI_APP_HOST | Host which RedisInsight should listen to. | String | `0.0.0.0` on Docker and `127.0.0.1` on Windows, Mac, and Linux. |
| RI_LOG_LEVEL | Configures the log level of the application. Possible values are - `"DEBUG"`, `"INFO"`, `"WARNING"`, `"ERROR`" and `"CRITICAL"`. | String | `"WARNING"` |
| RI_FILES_LOGGER | Log to file	| Boolean | `False` |
