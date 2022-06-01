# Redis documentation

## Clients

All clients are listed under language specific sub-folders of [clients](./clients)

The path follows the pattern: ``clients/{language}/github.com/{owner}/{repository}.json``.
The ``{language}`` component of the path is the path-safe representation
of the full language name which is mapped in [languages.json](./languages.json).

Each client's JSON object represents the details displayed on the [clients documentation page](https://redis.io/docs/clients).

For example [clients/python/github.com/redis](./clients/python/github.com/redis/redis-py.json):

```
{
    "name": "redis-py",
    "description": "Mature and supported. Currently the way to go for Python.",
    "recommended": true
}
```

## Commands

Redis commands are described in the `commands.json` file that is auto generated
from the Redis repo based on the JSON files in the commands folder.
See: https://github.com/redis/redis/tree/unstable/src/commands
See: https://github.com/redis/redis/tree/unstable/utils/generate-commands-json.py

For each command there's a Markdown file with a complete, human-readable
description.
We process this Markdown to provide a better experience, so some things to take
into account:

*   Inside text, all commands should be written in all caps, in between
    backticks.
    For example: `INCR`.

*   You can use some magic keywords to name common elements in Redis.
    For example: `@multi-bulk-reply`.
    These keywords will get expanded and auto-linked to relevant parts of the
    documentation.

There should be at least two predefined sections: description and return value.
The return value section is marked using the @return keyword:

```
Returns all keys matching the given pattern.

@return

@multi-bulk-reply: all the keys that matched the pattern.
```

## Styling guidelines

Please use the following formatting rules (aiming for smaller diffs that are easier to review):

* No need for manual lines wrapping at any specific length,
  doing so usually means that adding a word creates a cascade effect and changes other lines.
* Please avoid writing lines that are too long,
  this makes the diff harder to review when only one word is changed. 
* Start every sentence on a new line.


## Checking your work

After making changes to the documentation, you can use the [spellchecker-cli package](https://www.npmjs.com/package/spellchecker-cli) to validate your spelling as well as some minor grammatical errors. You can install the spellchecker locally by running:

```bash
npm install --global spellchecker-cli
```

You can than validate your spelling by running the following

```
spellchecker --no-suggestions -f '**/*.md' -l en-US -q -d wordlist
```

Any exceptions you need for spelling can be added to the `wordlist` file.
