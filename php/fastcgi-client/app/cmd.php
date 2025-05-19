<?php

declare(strict_types=1);

use hollodotme\FastCGI\Client;
use hollodotme\FastCGI\Requests\GetRequest;
use hollodotme\FastCGI\SocketConnections\NetworkSocket;
use hollodotme\FastCGI\SocketConnections\UnixDomainSocket;

require __DIR__ . '/vendor/autoload.php';

(new class {
    public function runCommandLine(): void
    {
        $client = new Client();
        $request = new GetRequest(__FILE__, "");


        $connections = [
            new NetworkSocket('127.0.0.1', 9000),
            new NetworkSocket('127.0.0.1', 9001),
            new UnixDomainSocket('/var/run/php-fpm.sock'),
            new UnixDomainSocket('/var/run/php-fpm2.sock'),
        ];

        foreach ($connections as $connection) {
            $response = $client->sendRequest($connection, $request);

            $body = $response->getBody();

            var_dump(json_decode($body, true));
        }
    }

    public function runRequest(): void
    {
        echo json_encode(opcache_get_status(false));
    }

    public function __invoke(): void
    {
        if (PHP_SAPI == 'cli') {
            $this->runCommandLine();
        } else {
            $this->runRequest();
        }
    }
})();
