// ==UserScript==
// @name             Hacker News Title Catcher
// @match            https://hn.premii.com/*
// @version          1.0
// @run-at           document-idle
// ==/UserScript==

(() => {
    const setTitle = (title) => {
        if (title.length > 50) {
            title = title.substring(0, 50) + "...";
        }

        document.title = title + " | HN";
    };

    const checkForTitle = () => {
        const titleEl = document.querySelector('.page-comments .title');

        if (titleEl) {
            setTitle(titleEl.innerText);
        }
    };

    const pageEl = document.querySelector('.pages-container');
    if (!pageEl) {
        console.warn('HN Title Catcher: No page element found, aborting.');
        return;
    }

    const observer = new MutationObserver(checkForTitle);
    observer.observe(pageEl, {
        childList: true,
        subtree: true
    });
    checkForTitle();
})();
