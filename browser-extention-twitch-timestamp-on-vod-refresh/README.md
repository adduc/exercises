# Browser Extension: Twitch Timestamp on VOD refresh

## Description

This is a browser extension that adds the current timestamp of a Twitch VOD
to the URL when the page is refreshed. This allows the VOD to be resumed
from the same point.

## Why?

Twitch has functionality to track the progress a viewer has made through
a VOD, but it periodically fails to synchronize the progress with the
server. This causes the VOD to reset to the beginning the next time the
page is loaded. Also, when viewing VODs for currently live streams, reaching
the end of the VOD and refreshing the page can cause the VOD to reset to
the beginning.

## How?

A content script runs on twitch.tv pages, listening for the `play`, `pause`,
and `ended` events. When one of these events is detected, the current
timestamp of the VOD is sent to the background script. While the VOD is
playing, the content script also sends the timestamp to the background
script every 10 seconds.

The background script then listens for navigation requests to twitch.tv
pages, and adds the timestamp to the URL if it is not already present.

## Installation

1. Clone the repository
2. Open Firefox and navigate to `about:debugging`
3. Click on "This Firefox"
4. Click on "Load Temporary Add-on"
5. Select the `manifest.json` file in the repository
