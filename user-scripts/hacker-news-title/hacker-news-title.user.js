// ==UserScript==
// @name             Hacker News Title Catcher
// @match            https://hn.premii.com/*
// @version          1.0
// @run-at           document-idle
// ==/UserScript==

const MAX_TITLE_LENGTH = 50;
const TITLE_SELECTOR = '.page-comments .title';
const PAGE_SELECTOR = '.pages-container';

(() => {
    const setTitle = (title) => {
        if (title.length > MAX_TITLE_LENGTH) {
            title = title.substring(0, MAX_TITLE_LENGTH) + "...";
        }

        document.title = title + " | HN";
    };

    const checkForTitle = () => {
        const titleEl = document.querySelector(TITLE_SELECTOR);

        if (titleEl) {
            setTitle(titleEl.innerText);
        }
    };

    const pageEl = document.querySelector(PAGE_SELECTOR);
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
