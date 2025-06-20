<?php

/**
 * Opcache Exporter proof-of-concept
 *
 * This script, when invoked from the command line, will send a POST
 * request to a FastCGI server (e.g., PHP-FPM) to execute this script.
 * It will then retrieve the opcache status and print it.
 *
 * To prevent unauthorized access, it uses an access key that is
 * generated randomly and sent as part of the FastCGI parameters and the
 * POST request body to ensure only users that can provide FastCGI
 * parameters can access the opcache status.
 */

use hollodotme\FastCGI\Client;
use hollodotme\FastCGI\RequestContents\UrlEncodedFormData;
use hollodotme\FastCGI\Requests\PostRequest;
use hollodotme\FastCGI\SocketConnections\NetworkSocket;

require __DIR__ . '/vendor/autoload.php';

(new class {
    /**
     * Generates and executes a request to invoke his script via FastCGI
     */
    public function runCommand()
    {
        $access_key = hash('sha256', random_int(PHP_INT_MIN, PHP_INT_MAX));

        $form_data = new UrlEncodedFormData(['access_key' => $access_key]);

        $request = PostRequest::newWithRequestContent(__FILE__, $form_data);
        $request->setCustomVar('OPCACHE_EXPORTER_ACCESS_KEY', $access_key);

        $connection = new NetworkSocket('127.0.0.1', 9000);

        $client = new Client();
        $response = $client->sendRequest($connection, $request);
        $body = $response->getBody();
        $status = json_decode($body, true);

        var_dump($status);
    }

    public function serveRequest()
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            header('Allow: POST');
            header('Content-Type: text/plain');
            echo 'Method Not Allowed';
            exit;
        } elseif (!isset($_SERVER['OPCACHE_EXPORTER_ACCESS_KEY'])) {
            http_response_code(500);
            header('Content-Type: text/plain');
            error_log('server param OPCACHE_EXPORTER_ACCESS_KEY is not set');
            echo 'Internal Server Error';
            exit;
        } elseif (empty($_POST['access_key'])) {
            http_response_code(403);
            header('Content-Type: text/plain');
            error_log('Access denied: POST parameter access_key is not set');
            echo 'Forbidden';
            exit;
        } elseif (!hash_equals($_SERVER['OPCACHE_EXPORTER_ACCESS_KEY'], $_POST['access_key'])) {
            http_response_code(403);
            header('Content-Type: text/plain');
            error_log('Access denied: access key mismatch');
            echo 'Forbidden';
            exit;
        }

        echo json_encode(opcache_get_status(false));
    }

    public function __invoke()
    {
        if (PHP_SAPI == "cli") {
            $this->runCommand();
        } else {
            $this->serveRequest();
        }
    }
})();
