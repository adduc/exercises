# Exercise: Parsing Command-Line Options in Bash

## Context

I wanted to build a resilient options parser in Bash that could work on both bash and ash shells (like BusyBox). The goal was to create a parser that could handle options provided at any position in the command line, not just at the beginning, in order to be resilient against user input.
