# Exercise: Using symlinks for Github Action workflow development

This exercise shows how symlinks can be used to keep associated Github Workflows close to relevant code without breaking Github Actions.

## Context

While Github Actions mandates that workflows be stored in the
`.github/workflows` directory, I wanted to figure out a way to keep
workflows separated by exercise to make them easier to find and
maintain.

## Attempt 1: symlinks in the `.github/workflows` directory (failed)

I tried creating a workflow in an exercise directory and creating a symlink in the `.github/workflows` directory to point to the workflow, but Github Actions did not resolve the symlink.

## Attempt 2: symlinks to the `.github/workflows` directory (success)

If one direction didn't work, maybe the other would. I created a workflow in the `.github/workflows` directory and created a symlink in the exercise directory to point to the workflow. This worked, while still allowing me to open the exercise in VSCode and see all relevant files.