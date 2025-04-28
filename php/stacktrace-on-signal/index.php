<?php

declare(strict_types=1);

pcntl_async_signals(true);

pcntl_signal(SIGHUP, function ($signal) {
    echo str_repeat('-', 15) . "\n";
    echo "Received signal: {$signal} \n";
    echo "Stack trace at the time of signal: \n";
    error_log((new Exception())->getTraceAsString());
});

(new class
{
    function __invoke()
    {
        $pid = getmypid();
        echo <<<EOF
        This is a test script to demonstrate how signals are pushed onto the stack,
        which allows us to capture the stack trace of what was happening when the
        signal was received. It can be used as an aid to debug "hanging" processes
        that might be stuck in a loop or waiting for an event.

        To test this, run this script and then in another terminal, run
        the following one or more times:

        kill -s HUP {$pid}


        EOF;

        while (true) {
            sleep(255);
        }
    }
})();
