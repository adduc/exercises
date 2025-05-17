# Logging stack traces on process signals in PHP

This exercise demonstrates how stack traces can be logged when a PHP process receives a signal, such as SIGHUP or SIGUSR1. This is useful for debugging and understanding the state of the application when it appears to be unresponsive.

## Context

This was [originally written in 2021][gist] when I was working on some
crons that suddenly started to take longer than expected to run. I
wanted a light-weight way to be able to trigger stack traces on demand
in production without having to modify the code or restart the
application. If I recall correctly, I ended up sending a signal every
few seconds to identify how the script was progressing to identify
where the bottleneck was. These days, I would rely on an APM tool like
New Relic or DataDog, but this is still a useful technique for
situations where they are not available.

<!-- Links -->

[gist]: https://gist.github.com/adduc/d58a33c899cf078006b7f00291668477
