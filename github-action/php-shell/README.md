# Using a PHP Shell in GitHub Actions

This exercise shows how the shell can be set in a GitHub Action workflow to run PHP commands.

## Example

```yaml
name: "Example: PHP Shell"

on:
    push:

jobs:
  php:
    runs-on: ubuntu-24.04
    steps:
      - name: Shell test
        shell: /usr/bin/env php {0}
        run: |-
          <?php
          echo "Hello from PHP!\n";
```
