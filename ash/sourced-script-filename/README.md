# Calculating the current script's path in Busybox' ash shell

This exercise demonstrates one method of calculating the current script's path in Busybox' ash shell. This is useful in situations where
the script needs to be aware of its own location, such as when it needs to source other scripts or access files relative to its own directory.

## Context

I try to purposefully design scripts and shell libraries to be invoked
from anywhere. This design philosophy occasionally requires the script
to know where it is located, such as when it needs to source other scripts or access files relative to its own directory. While this is
easily accomplished in bash, it is not as straightforward in Busybox' ash shell.

## Lessons Learned

Reading through the source code for Busybox' ash shell, there did not
appear to be an official way to determine the current script's path.
However, I saw that the sourced script's name would be included in error
messages. This exercise uses that information to determine the script's
path, but it is not foolproof and there are likely some script names
that would break this method.

Claude suggested using the `caller` command, but it doesn't appear to be
included in Busybox' ash shell, and there are no references to it in the
source code that I could find. An alternative solution suggested by
Claude involved setting a "SOURCED_SCRIPT" variable prior to sourcing
scripts. This is more reliable than the method used in this exercise,
but it requires the script responsible for sourcing to be modified,
which is not always feasible.

## Usage

A Makefile is included to invoke the provided scripts in an Alpine docker container.
