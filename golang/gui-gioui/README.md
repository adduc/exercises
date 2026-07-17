# Exercise: Building a simple GUI in Golang using GioUI

This exercise demonstrates how a small GUI application can be built in Golang
using the GioUI library. The application will display a simple window with a
button that, when clicked, updates a label with a message.

## Context

I have a Dell tablet with a limited amount of memory available, and am
interested in evaluating different solutions for building a lightweight GUI
application.

## Thoughts

As an immediate mode GUI, I appreciate how much it both has built-in
abstractions and allows for customization if you want to go deeper. While
Claude was able to build out a simple GUI and add some hooks for buttons to
update labels, the forced animations out of box and memory usage at 50 MiB base
are a bit concerning for my use case. If I have a usecase for a custom GUI, I
think GioUI is a good option, but I don't think it's a good fit for what I'm
currently looking for.
