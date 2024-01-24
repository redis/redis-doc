---
Title: Supported environment variables
date: 2024-01-30 10:00:00
weight: 60
categories: ["RI"]
path: install/install-redisinsight/env-variables
altTag: Supported environment variables
---
You can configure RedisInsight with the following environment variables.

| Variable | Purpose | Default | Additional Info | Example |
| --- | --- | --- | --- | --- |
| RI_APP_PORT | The port that RedisInsight listens on | `5540` | See [Express Documentation](https://expressjs.com/en/api.html#app.listen)| `-e RI_APP_PORT=8001` |
| RI_APP_HOST | The host that RedisInsight listens on | <ul><li> docker: 0.0.0.0 <li> desktop: 127.0.0.1 </ul> | See [Express Documentation](https://expressjs.com/en/api.html#app.listen)| `-e RI_APP_HOST=127.0.0.1` |
| RI_SERVER_TLS_KEY | Private key for HTTPS | n/a | Private key in [PEM format](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/#ftoc-heading-3). May be a path to a file or a string in PEM format.| `-e RI_SERVER_TLS_KEY={key}` |
| RI_SERVER_TLS_CERT | Certificate for supplied private key | n/a | Public certificate in [PEM format](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/#ftoc-heading-3)| `-e RI_SERVER_TLS_CERT={certificate}` |
| RI_ENCRYPTION_KEY | Key to encrypt data with | n/a | Redisinsight stores sensitive information (database passwords, Workbench history, etc.) locally (using [sqlite3](https://github.com/TryGhost/node-sqlite3)). This variable allows to store sensitive information encrypted using the specified encryption key. <br /> `Note:` The same encryption key should be provided for subsequent `docker run` commands with the same volume attached to decrypt the information. | `-e RI_SERVER_TLS_CERT={encryption_key}` |
| RI_LOG_LEVEL | Configures the log level of the application. | `info` | Supported logging levels are prioritized from 0 to 6 (highest to lowest): <ul> <li>error: 0, <li> warn: 1, <li> info: 2, <li> http: 3 <li> verbose: 4, <li> debug: 5, <li> silly: 6 </ul> | `-e RI_LOG_LEVEL=debug` |
| RI_FILES_LOGGER | Log to file | `true` | By default, you can find log files in the following folders: <ul> <li> docker: `/data/logs` <li> desktop: `<user-home-dir>/.refisinsight-app/logs` </ul>| `-e RI_FILES_LOGGER=false` |
| RI_STDOUT_LOGGER | Log to STDOUT | `true` | | `-e RI_STDOUT_LOGGER=false` |
