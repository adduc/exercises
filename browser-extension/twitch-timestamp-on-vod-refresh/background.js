/**
 * The background script is responsible for listening for messages
 * containing URLs and timestamps, and then redirecting navigation
 * requests for the URL to the URL with the timestamp as a query
 * parameter.
 */

/**
 * Configuration
 */

const logsEnabled = false;

/**
 * State
 */

let timestamps = {};

/**
 * Helpers
 */

const log = (...message) => logsEnabled && console.log(...message);

const formatTime = (timestamp) => {
    const hours = Math.floor(timestamp / 3600);
    const minutes = Math.floor((timestamp % 3600) / 60);
    const seconds = (timestamp % 60).toFixed(0);

    return `${hours}h${minutes}m${seconds}s`;
};

/**
 * Actions
 */

const receiveMessage = (request, sender, sendResponse) => {
    log('Received Message', request);
    timestamps[request.url] = request.timestamp;
};

const beforeNavigate = (details) => {
    const timestamp = timestamps[details.url] ?? null;
    if (!timestamp) {
        return;
    }

    log('Before Navigate', { timestamp, url: details.url });

    const newUrl = new URL(details.url);

    const formattedTimestamp = formatTime(timestamp);

    // avoid infinite redirects if the timestamp is already set to the correct value
    if (newUrl.searchParams.get('t') === formattedTimestamp) {
        return;
    }

    newUrl.searchParams.set('t', formattedTimestamp);
    browser.tabs.update(details.tabId, { url: newUrl.toString() });
};

/**
 * Listeners
 */

// listen for messages from the content script, and add them to the
// timestamps object based on the url
browser.runtime.onMessage.addListener(receiveMessage);


// Listen for navigation requests to twitch.tv and add the timestamp to the url
browser.webNavigation.onBeforeNavigate.addListener(beforeNavigate, {
    url: [{ hostEquals: 'www.twitch.tv' }],
});
