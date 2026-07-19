# Exercise: Building a simple GUI in Golang using Wails

This exercise demonstrates how a small GUI application can be built in Golang
using the Wails framework. The application will display a simple window with a
button that, when clicked, updates a label with a message.

## Context

I have a few ideas for desktop applications that I would like to build, but its
been years since I last built a GUI and wanted to evaluate modern toolkits. I had heard Wails was the Golang-equivalent to Rust's Tauri and wanted to try it out. I was also interested in how much memory it would require, given the dependency on some form of webview.

## Thoughts

While I was able to build a simple GUI application using Wails, my concerns with memory usage were confirmed. The application, when built and run, consumed
around 350 MiB of memory (total RSS, including the webview). While this might be acceptable for some applications, it is quite high for a simple GUI application.
