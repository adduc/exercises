# Exploring the Task Command Runner: First Impressions

This is a brief exploration of the [task][] command runner, comparing it
to [make][] and [just][].

## Context

`make` has been my preferred command runner for many years. While it
remains reliable, I am still happy with it, a colleague proposed a few
alternatives, including `just`. This is an exploration of its features
and usability.

## Initial Impressions

**Pros**:

Here are some of the things I liked about Task:

- The precondition support is a significant improvement over `make`'s
  implementation, allowing you to define multiple commands to run to
  determine if the recipe should be executed.
- The dotenv support is configurable, allowing you to load environment
  variables from `.env` or other files. The implementation is
  well thought out and intuitive when reading the taskfile. In contrast,
  `just` requires a flag, which is easy to overlook.
- Native support for watching files and executing tasks on changes is
  wonderful for development workflows.
- `task`'s concurrency and parallelism appears to match the same support
  as `make`.

**Cons**:

While `task` has a lot of great features, there are a few limitations
worth noting:

- Its execution model works similarly to `make`, where each line is
  invoked separately through a shell. This means that escaping line
  returns are needed to run multi-line commands correctly. This was
  something `just` mitigated through their shebang solution, and I
  would have liked to see something similar here.
- Autocompletion support is supposedly available, but it does not seem
  to work correctly in my shell (bash), even after running the eval
  command recommended in the documentation.
- While there is support for wildcards in recipe names (e.g. `build-*`),
  there is no support for dynamic generation of recipe names or
  providing context for the help documentation or autocomplete. I use
  dynamic recipes for docker images, where there are many variants but
  I frequently want to build only one at a time.

## Final Thoughts

I appreciate many of the features `task` offers, but I remain skeptical
about whether it provides enough added value to justify replacing `make`
in my workflow.

<!-- Links -->

[task]: https://taskfile.dev/
[just]: https://just.systems/
[make]: https://www.gnu.org/software/make/
