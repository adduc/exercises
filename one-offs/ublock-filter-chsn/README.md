# Fixing browser crashes when watching CHSN games

This exercise demonstrates one way to fix browser crashes when watching CHSN games by replacing thumbnails with tiny images.

## Context

I recently subscribed to CHSN to watch White Sox games, but when I
attempted to watch a game from the day before, my browser crashed. I
experienced this both on Firefox and Chrome. After profiling the page
during its initial load, I discovered that the CPU and memory usage was
caused from an attempt to load and process 2,500+ thumbnails.

## Solution

Using uBlock Origin, I created a filter to rewrite the thumbnail requests to a 1x1 transparent GIF. Blocking the requests caused a ReactJS error and the page to incorrectly render, but rewriting the requests to a 1x1 transparent GIF allowed the page to load correctly without crashing the browser.

## Filters

```
# Block excessive thumbnail loads to prevent browser crashes
||chsn.asset.viewlift.com/ArchiveA/*/Thumbnail-*.jpg$rewrite=abp-resource:1x1-transparent-gif
```
