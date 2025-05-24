<?php

match ($_SERVER['REQUEST_URI']) {
    '/404' => http_response_code(404),
    '/403' => http_response_code(403),
    '/500' => http_response_code(500),
    default => http_response_code(200),
};

echo "${_SERVER['REQUEST_URI']} - " . http_response_code() . "\n";

echo "<br>Try /404, /403, /500, or /anything<br>";
