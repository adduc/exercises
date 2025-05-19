<?php

require __DIR__ . '/vendor/autoload.php';

use Psr\Http\Message\ServerRequestInterface;
use React\EventLoop\Loop;
use React\EventLoop\LoopInterface;
use React\Http\HttpServer;
use React\Http\Message\Response;
use React\Socket\SocketServer;

$loop = Loop::get();

$class = (new class($loop) {
    private int $counter = 0;

    public function __construct(LoopInterface $loop)
    {
        $loop->addPeriodicTimer(1, function () {
            $this->counter++;
        });
    }

    public function serveMetrics(): Response
    {
        $body = <<<EOT
            # HELP example_gauge Example gauge metric
            # TYPE example_gauge gauge
            example_gauge{label="example"} {$this->counter}
        EOT;

        return new Response(
            headers: ['Content-Type' => 'text/plain; version=0.0.4'],
            body: $body,
        );
    }

    public function serveLandingPage(): Response
    {
        return Response::html('<h1>Example Exporter</h1><a href="/metrics">Metrics</a>');
    }

    public function serveNotFound(): Response
    {
        return Response::plaintext('Not Found', 404);
    }

    public function serveErrorHandler(): Response
    {
        return Response::plaintext('Internal Server Error', 500);
    }

    public function __invoke(ServerRequestInterface $request): Response
    {
        try {
            return match ($request->getUri()->getPath()) {
                '/metrics' => $this->serveMetrics(),
                '/' => $this->serveLandingPage(),
                default => $this->serveNotFound(),
            };
        } catch (\Throwable $e) {
            error_log($e);
            return $this->serveErrorHandler();
        }
    }
});

$socket = new SocketServer('0.0.0.0:8080', [], $loop);
(new HttpServer($class))->listen($socket);

echo "Server running at http://0.0.0.0:8080" . PHP_EOL;
