#!/usr/bin/env php
<?php declare(strict_types=1);

(new class {
  public function __invoke(){
    match ($_SERVER['REQUEST_URI']) {
        '/2018-06-01/runtime/invocation/next' => $this->nextInvocation(),
        '/2018-06-01/runtime/invocation/example/response' => $this->invocationResponse(),
        default => $this->error(),
    };
  }

  protected function nextInvocation() {
    http_response_code(200);
    header('Lambda-Runtime-Aws-Request-Id: example');
    sleep(3);
  }

  protected function invocationResponse() {
    http_response_code(200);
  }

  protected function error() {
    http_response_code(404);
    echo "Not Found";
  }
})();
