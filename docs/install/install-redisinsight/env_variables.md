---
Title: Supported environment variables
date: 2024-01-30 10:00:00
weight: 60
categories: ["RI"]
path: install/install-redisinsight/env_variables
altTag: Supported environment variables
---
You can configure RedisInsight with the following environment variables.

| Variable | Purpose | Default | Additional Info |
| --- | --- | --- |--- |
| RI_APP_PORT | The port that RedisInsight listens on | `5540` | See [Express Documentation](https://expressjs.com/en/api.html#app.listen)|
| RI_APP_HOST | The host that RedisInsight listens on | 0.0.0.0 | See [Express Documentation](https://expressjs.com/en/api.html#app.listen)|
| RI_SERVER_TLS_KEY | Private key for HTTPS | n/a | Private key in [PEM format](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/#ftoc-heading-3). May be a path to a file or a string in PEM format.|
| RI_SERVER_TLS_CERT | Certificate for supplied private key | n/a | Public certificate in [PEM format](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/#ftoc-heading-3)|
| RI_ENCRYPTION_KEY | Key to encrypt data with | n/a | Redisinsight stores sensitive information (database passwords, Workbench history, etc.) locally (using [sqlite3](https://github.com/TryGhost/node-sqlite3)). This variable allows to store sensitive information encrypted using the specified encryption key. <br /> `Note:` Securely store the specified encryption key to be able to provide it in the future (e.g. during the startup process), otherwise RedisInsight will not be able to decrypt the information. |
| RI_LOG_LEVEL | Configures the log level of the application. Possible values are - `"DEBUG"`, `"INFO"`, `"WARNING"`, `"ERROR`" and `"CRITICAL"`. | `INFO` | |
| RI_FILES_LOGGER | Log to file | 'true' | |
| RI_STDOUT_LOGGER | Log to STDOUT | 'true' | |
