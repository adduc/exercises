# Exercise: Repository Pattern in Go

This is a simple example of how to implement the repository pattern in Go.

## Context

While working on a project, I ran into issues with the way I was handling the database connection. I was using a global variable to store the connection, and I was not able to mock the database connection in my tests. I decided to implement the repository pattern to solve this issue.

## Links

This exercise takes inspiration from https://threedots.tech/post/repository-pattern-in-go/