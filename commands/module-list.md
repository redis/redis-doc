Returns information about the modules loaded to the server.

@return

@array-reply: list of loaded modules.
Each element in the list represents a loaded module and is in itself a list of property names and their values.
The following properties are reported for each module:

*   `name`: Name of the module.
*   `ver`: Version of the module.
