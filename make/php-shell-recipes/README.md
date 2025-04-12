# Writing Makefile recipes using PHP

This exercise shows how Makefile can be configured to run PHP code instead of bash scripts when executing recipes.

## Example

```makefile
# Pass the entire recipe to the shell
.ONESHELL:

# Use env to run PHP (determined from PATH)
SHELL = /usr/bin/env

# Set the shell flags to run PHP code
# The `-r` flag allows running PHP code directly from the command line without requiring a PHP script file
.SHELLFLAGS = php -r

# Example recipe to demonstrate functionality
# This recipe prints a greeting and a variable value
#
# In Makefile, a single `$` is used for Make's own variables, so to
# pass a literal `$` to the shell (in this case, PHP), you need to
# escape it by using `$$`. This ensures that PHP receives the
# correct syntax for its variables.
example:
	@// include '@' to suppress Make from echoing this script
	echo "Hello, World!\n";
	$$a = "Test!";
	echo "$$a\n";
```

**Running the Makefile:**

```bash
$ make example
Hello, World!
Test!
```
