# Redis documentation

## Clients

All clients are listed in the `clients.json` file.
Each key in the JSON object represents a single client library.
For example:

```
"Rediska": {

  # A programming language should be specified.
  "language": "PHP",

  # If the project has a website of its own, put it here.
  # Otherwise, lose the "url" key.
  "url": "http://rediska.geometria-lab.net",

  # A URL pointing to the repository where users can
  # find the code.
  "repository": "http://github.com/Shumkov/Rediska",

  # A short, free-text description of the client.
  # Should be objective. The goal is to help users
  # choose the correct client they need.
  "description": "A PHP client",

  # An array of Twitter usernames for the authors
  # and maintainers of the library.
  "authors": ["shumkov"]

}
```

## Commands

Redis commands are described in the `commands.json` file.

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

Please use the following formatting rules:

* No need for manual lines wrapping at any specific length, doing so usually
  means that adding a word creates a cascade effect and changes other lines.
* Please avoid writing lines that are too long, this makes the diff harder to
  review when only one word is changed. 
* Start every sentence on a new line.

Luckily, this repository comes with an automated Markdown formatter.
To only reformat the files you have modified, first stage them using `git add`
(this makes sure that your changes won't be lost in case of an error), then run
the formatter:

```
$ rake format:cached
```

The formatter has the following dependencies:

* Redcarpet
* Nokogiri
* The `par` tool
* batch

Installation of the Ruby gems:

```
gem install redcarpet nokogiri batch
```

Installation of par (OSX):

```
brew install par
```

Installation of par (Ubuntu):

```
sudo apt-get install par
```

## Checking your work

You should check your changes using Make:

```
$ make
```

This will make sure that JSON and Markdown files compile and that all
text files have no typos.

You need to install a few Ruby gems and [Aspell][aspell] to run these checks.
The gems are listed in the `.gems` file. Install them with the
following command:

```
$ gem install $(sed -e 's/ -v /:/' .gems)
```

The spell checking exceptions should be added to `./wordlist`.

[aspell]: http://aspell.net/
