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

    const observer = new MutationObserver(checkForTitle);

    const pageEl = document.querySelector('.pages-container');
    observer.observe(pageEl, {
        childList: true,
        subtree: true
    });
    checkForTitle([], observer);
})();
