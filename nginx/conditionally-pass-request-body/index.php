<?php

if ($_SERVER['REQUEST_URI'] === '/error/external') {
    http_response_code(404);
    echo 'External Server Error (from PHP)';
    exit;
}

if ($_SERVER['REQUEST_URI'] === '/error/internal') {
    http_response_code(500);
    echo 'Internal Server Error (from PHP)';
    exit;
}

print_r([
    '$_GET' => $_GET,
    '$_POST' => $_POST,
    'php://input' => file_get_contents('php://input'),
]);
