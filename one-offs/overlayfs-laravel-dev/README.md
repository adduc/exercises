# Using OverlayFS in application development

This exercise demonstrates how OverlayFS can be used to separate
framework code from application code in a development environment.

## How this works

OverlayFS works by taking a lower directory (the framework code) and
an upper directory (the application code) and merging them together to
appear as a single directory. Changes made to the merged directory are
propagated to the upper directory, while the lower directory remains
unchanged.

This can be useful for proof-of-concepts where most of the framework's
boilerplate code is not changed, but still needed to run the application. Thus, the changed code for the purpose of the proof-of-concept can be kept separate from the framework code.

## Pre-requisites

- [fuse-overlayfs][]
- [GNU Make][]

## Usage

A Makefile is provided to simplify the process of creating the
overlay filesystem. The Makefile contains the following targets:

- `mount`: Mounts the overlay filesystem.
- `unmount`: Unmounts the overlay filesystem.

<!-- Links -->
[fuse-overlayfs]: https://github.com/containers/fuse-overlayfs
[GNU Make]: https://www.gnu.org/software/make/
