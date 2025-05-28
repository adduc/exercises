# Tracking cpu usage of queued jobs, scheduled tasks and commands in Laravel

This exercise demonstrates how listeners can be defined to track when queued jobs, scheduled tasks, and commands are executed in a Laravel application. This particular implementation tracks the CPU usage of these tasks, which can help identify performance bottlenecks or unexpected resource consumption.

## Context

I recently worked with a Laravel application that occasionally generated a large amount of CPU usage while requests appeared to be running normally. To get a better sense of what type of background tasks were running, I wanted to track the CPU usage of queued jobs, scheduled tasks, and commands.

## Implementation

Listeners are defined in `app/Listeners`, and are automatically registered by Laravel. They write to a separate log channel to avoid cluttering the main application log.
