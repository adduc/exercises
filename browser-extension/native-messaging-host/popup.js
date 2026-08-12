const HOST_NAME = "com.adduc.example";

// Firefox exposes a promise-based `browser` global; Chrome only has the
// callback-based `chrome` global. Branching on that is the standard
// cross-browser WebExtensions idiom (what libraries like webextension-polyfill
// automate for larger projects).
document.getElementById("send").addEventListener("click", async () => {
  const output = document.getElementById("output");
  const text = document.getElementById("text").value;
  output.value = "Sending...";

  try {
    if (typeof browser !== "undefined") {
      const response = await browser.runtime.sendNativeMessage(HOST_NAME, { text });
      output.value = JSON.stringify(response, null, 2);
    } else {
      chrome.runtime.sendNativeMessage(HOST_NAME, { text }, (response) => {
        if (chrome.runtime.lastError) {
          output.value = `Error: ${chrome.runtime.lastError.message}`;
          return;
        }
        output.value = JSON.stringify(response, null, 2);
      });
    }
  } catch (err) {
    output.value = `Error: ${err.message}`;
  }
});
