# Exercise: Building a simple GUI in Rust using Slint

This exercise demonstrates how a small GUI application can be built in Rust
using the Slint framework. The application will display a simple window with a
button that, when clicked, updates a label with a message.

## Context

I have a Dell tablet with a limited amount of memory available, and am
interested in evaluating different solutions for building a lightweight GUI
application.

## Thoughts

Support for automatic light/dark mode out of box is a nice feature, and the
memory usage of the application was around 20 MiB (total RSS) when built and
run. Unique to Slint, there were VSCode extensions available to preview and
tweak the UI, which is a nice feature.

Unfortunately, the font rendering doesn't appear to look as good as other
toolkits I've evaluated; it appears to be due Slint's use of a rust-based stack
for font rendering, which is not as mature as other toolkits that leverage
native font rendering. If the font rendering can be improved, Slint seems to be
a good fit for my use case, as it provides a balance between functionality and
resource usage.
