# Browser Extension: URL State Replacer

## Description

This is a simple browser extension that replaces the URL state with a new state on blur and visibilitychange for example.com pages.

## Why?

I am putting together a proof of concept for a browser extension that tracks
timestamps of a video player.

## Drawbacks

- While this avoids polluting the back button history with new entries,
  it does pollute the general browser history with new entries.

## Installation

1. Clone the repository
2. Open Firefox and navigate to `about:debugging`
3. Click on "This Firefox"
4. Click on "Load Temporary Add-on"
5. Select the `manifest.json` file in the repository

## Usage

1. Open Firefox and navigate to example.com
2. Click on a different tab or window.
3. The extension will replace the URL state with a new state.