# Exploring the Just Command Runner: First Impressions

This is a brief exploration of the [just][] command runner, comparing
it to [make][] and [task][]

## Context

`make` has been my preferred command runner for many years. While it
remains reliable, I am still happy with it, a colleague proposed a few
alternatives, including `just`. This is an exploration of its features
and usability.

## Initial Impressions

**Pros**:

Here are some of the things I liked about Just:

- The manual is comprehensive and built using `mdbook`, making it easy
  to navigate and read.
- Just will search ancestor directories for a `justfile`, which is
  great for projects where you find yourself in multiple subdirectories
  and want to run a command.
- Shebang (`#!`) recipes provide a convenient way to write bash scripts
  without the need to escape multiple lines. They are also ideal for including one-off scripts, such as those I often write in PHP.
- `just` has built-in support to list all defined recipes, including the
  comment prior to the recipe.

**Cons**:

Despite its strengths, `just` has some limitations worth noting.

- The tool's name is challenging to search for online. Both `just` and
  `make` are common terms, but make has decades of backlinks that make
  it easier to find relevant results, while `just` is new and faces an
  uphill battle.
- `just` lacks built-in support for executing recipes in parallel,
  instead relying on external tools like GNU parallel or xargs. This is
  a notable limitation, as GNU parallel, xargs, and other solutions
  don't have the context `just` and `make` have.
- `just` lacks support for dynamic recipes (variables sort of get you there)
- `just` lacks support for autocompleting recipe parameters
- Options are positional (interpreted before recipe name, not after)
- The syntax for multiline recipe comments can be awkward if you want
  them to display in the help text.
- `just` lacks support for conditional recipe execution, where `make` is
  file-based and `task` can be explicitly configured commands to run to
  determine whether the recipe should execute.

## Final Thoughts

I like a lot of what `just` has to offer, but I am skeptical it
provides enough of a value-add to warrant moving away from `make` for
my workflow.


<!-- Links -->

[just]: https://just.systems/
[task]: https://taskfile.dev/
[make]: https://www.gnu.org/software/make/
