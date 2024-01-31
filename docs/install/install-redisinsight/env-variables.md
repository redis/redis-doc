---
title: "Environment variables"
linkTitle: "Environment variables"
weight: 1
description: >
    RedisInsight supported environment variables
---
You can configure RedisInsight with the following environment variables.

| Variable | Purpose | Default | Additional info |
| --- | --- | --- | --- |
| RI_APP_PORT | The port that RedisInsight listens on | <ul><li> Docker: 5540 <li> desktop: 5530 </ul> | See [Express Documentation](https://expressjs.com/en/api.html#app.listen)|
| RI_APP_HOST | The host that RedisInsight connects to | <ul><li> Docker: 0.0.0.0 <li> desktop: 127.0.0.1 </ul> | See [Express Documentation](https://expressjs.com/en/api.html#app.listen)|
| RI_SERVER_TLS_KEY | Private key for HTTPS | n/a | Private key in [PEM format](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/#ftoc-heading-3). Can be a path to a file or a string in PEM format.|
| RI_SERVER_TLS_CERT | Certificate for supplied private key | n/a | Public certificate in [PEM format](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/#ftoc-heading-3). Can be a path to a file or a string in PEM format.|
| RI_ENCRYPTION_KEY | Key to encrypt data with | n/a | Available only for Docker. <br> Redisinsight stores sensitive information (database passwords, Workbench history, etc.) locally (using [sqlite3](https://github.com/TryGhost/node-sqlite3)). This variable allows you to store sensitive information encrypted using the specified encryption key. <br />Note: The same encryption key should be provided for subsequent `docker run` commands with the same volume attached to decrypt the information. |
| RI_LOG_LEVEL | Configures the log level of the application. | `info` | Supported logging levels are prioritized from highest to lowest: <ul> <li>error<li> warn<li>info<li> http<li> verbose<li> debug<li> silly</ul> |
| RI_FILES_LOGGER | Log to file | `true` | By default, you can find log files in the following folders: <ul> <li> Docker: `/data/logs` <li> desktop: `<user-home-dir>/.refisinsight-app/logs` </ul>|
| RI_STDOUT_LOGGER | Log to STDOUT | `true` | |
