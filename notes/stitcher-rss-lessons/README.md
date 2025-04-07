# Reviewing Stitcher RSS Code

It's been five years since the Unofficial Feeds for Stitcher Premium service was sunset. The codebase was originally written in 2019 to generate RSS feeds for subscribers to access paywalled content on Stitcher. The code uses Lumen 7, a micro-framework of Laravel, to handle HTTP requests and generate RSS feeds. It overwent multiple iterations to improve performance, add features, and fix bugs.


## Caching

- Use a SQLite database locally instead of files. This would have made backups easier, and potentially improve performance.
