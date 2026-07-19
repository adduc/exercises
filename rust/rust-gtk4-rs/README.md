# Exercise: Building a simple GUI in Rust using gtk4-rs

This exercise demonstrates how a small GUI application can be built in Rust
using the gtk4-rs framework. The application will display a simple window with a
button that, when clicked, updates a label with a message.

## Context

I have a Dell tablet with a limited amount of memory available, and am
interested in evaluating different solutions for building a lightweight GUI
application.

## Thoughts

Support for automatic light/dark mode out of box is a nice feature, and the memory usage of the application was around 50 MiB (total RSS) when built and run. Among the toolkits I've evaluated, gtk4-rs seems to be a good fit for my use case, as it provides a balance between functionality and resource usage.
