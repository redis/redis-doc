Kill an in-flight function.


The `FUNCTION KILL` command can be used only on functions that did not modify the dataset during their execution (since stopping a read-only script does not violate the scripting engine's guaranteed atomicity).

For more information please refer to [Introduction to Redis Functions](/topics/function)

@return

@simple-string-reply
