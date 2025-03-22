/**
 * This script modifies the timestamp of the current page
 * every 10 seconds, as well as when the page loses focus or is
 * otherwise not visible.
 */

let lastExecution = 0;

const replaceState = () => {
    const timestamp = (new Date()).getTime();
    // if executed in the last 9.5 seconds, do not execute again
    if (timestamp - lastExecution < 9500) {
        return;
    }

    const url = new URL(window.location);
    url.searchParams.set('timestamp', timestamp);

    window.history.replaceState({}, '', url.toString());

    lastExecution = timestamp;
}

// when the page loses focus
document.addEventListener('blur', () => {
    console.log('blur');
    replaceState();
});

// when the page is hidden or otherwise not visible
document.addEventListener('visibilitychange', () => {
    console.log('visibilitychange');
    replaceState();
});

// set timestamp every 10 seconds
setInterval(() => {
    console.log('setInterval');
    replaceState();
}, 10000);