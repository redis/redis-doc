Redis documentation
===


Clients
---

All clients are listed in the `clients.json` file. Each key in the JSON
object represents a single client library. For example:

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


Commands
---

Redis commands are described in the `commands.json` file.

For each command there's a Markdown file with a complete, human-readable
description. We process this Markdown to provide a better experience, so
some things to take into account:

* Inside text, all commands should be written in all caps, in between
backticks. For example: <code>`INCR`</code>.

* You can use some magic keywords to name common elements in Redis. For
example: `@multi-bulk-reply`. These keywords will get expanded and
auto-linked to relevant parts of the documentation.

There should be at least three pre-defined sections: time complexity,
description and return value. These sections are marked using magic
keywords, too:

    @complexity

    O(n), where N is the number of keys in the database.


    @description

    Returns all keys matching the given pattern.


    @return

    @multi-bulk-reply: all the keys that matched the pattern.


Styling guidelines
---

Please wrap your text to 80 characters. You can easily accomplish this
using a CLI tool called `par`.


Checking your work
---

Once you're done, the very least you should do is make sure that all
files compile properly. You can do this by running Rake inside your
working directory.

    $ rake
