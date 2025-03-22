/**
 * This script extracts the current timestamp of the VOD and sends it to
 * the background script every 10 seconds, as well as when the page
 * loses focus or is otherwise not visible.
 */

/**
 * Configuration
 */

const logsEnabled = false;
const interval = 10000;

/**
 * State
 */

let lastTimestamp = 0;
let intervalID = null;

/**
 * Helpers
 */

const log = (...message) => logsEnabled && console.log(...message);

/**
 * Actions
 */

const sendTimestamp = (action) => {
    log('sendTimestamp', action);
    const currentTime = document.querySelector('.video-ref video').currentTime

    // if we can't get the current time, do not send the timestamp
    if (currentTime === 0) {
        return;
    }

    // if the current time is the same as the last timestamp, do not
    // send the timestamp to avoid wasting resources
    if (currentTime === lastTimestamp) {
        return;
    }

    lastTimestamp = currentTime;

    browser.runtime.sendMessage({
        timestamp: currentTime,
        url: window.location.href,
        action,
    });
};

const enableInterval = () => {
    // periodically send the timestamp
    intervalID = setInterval(() => sendTimestamp('interval'), interval);
}

const disableInterval = () => {
    clearInterval(intervalID);
    intervalID = null;
}

/*
 * Listeners
 */

// when the page loses focus
addEventListener('blur', (e) => sendTimestamp(e.type), true);

// when the page changes visibility (e.g. when the tab is changed)
addEventListener('visibilitychange', (e) => sendTimestamp(e.type), true);

// when video playback starts or stops, send the timestamp
addEventListener('play', (e) => {
    sendTimestamp(e.type);
    enableInterval();
}, true);

addEventListener('pause', (e) => {
    sendTimestamp(e.type);
    disableInterval();
}, true);

addEventListener('ended', (e) => {
    sendTimestamp(e.type);
    disableInterval();
}, true);
