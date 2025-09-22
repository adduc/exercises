#!/usr/bin/env php
<?php

declare(strict_types=1);

if ($argc < 2) {
    fprintf(STDERR, "Usage: %s <command> [args...]\n", $argv[0]);
    fprintf(STDERR, "Example: %s docker run --rm -i mcp/filesystem /\n", $argv[0]);
    exit(1);
}

// Build the command from arguments
$command = array_slice($argv, 1);
$commandString = implode(' ', array_map('escapeshellarg', $command));

// Descriptor specification for proc_open
$descriptors = [
    0 => ['pipe', 'r'],  // stdin
    1 => ['pipe', 'w'],  // stdout
    2 => ['pipe', 'w'],  // stderr
];

$log_file = __DIR__ . '/proxy_' . date('Y-m-d_H-i-s') . '.log';
if (file_exists($log_file)) {
    unlink($log_file); // Remove existing log file
}

// Open the log file for writing
$logHandle = fopen($log_file, 'a');
if ($logHandle === false) {
    fprintf(STDERR, "Failed to open log file: %s\n", $log_file);
    exit(1);
}

// Start the process
$process = proc_open($commandString, $descriptors, $pipes);

if (!is_resource($process)) {
    fprintf(STDERR, "Failed to start process: %s\n", $commandString);
    exit(1);
}

// Set non-blocking mode for all pipes
stream_set_blocking($pipes[0], false); // stdin to process
stream_set_blocking($pipes[1], false); // stdout from process
stream_set_blocking($pipes[2], false); // stderr from process
stream_set_blocking(STDIN, false);     // our stdin

// Set up signal handling for graceful shutdown
function signalHandler($signal) {
    global $process, $pipes;

    if (is_resource($process)) {
        // Close pipes
        foreach ($pipes as $pipe) {
            if (is_resource($pipe)) {
                fclose($pipe);
            }
        }

        // Terminate the process
        proc_terminate($process);
        proc_close($process);
    }

    exit(0);
}

// Register signal handlers (if available)
if (function_exists('pcntl_signal')) {
    pcntl_signal(SIGTERM, 'signalHandler');
    pcntl_signal(SIGINT, 'signalHandler');
}

// Main communication loop
while (true) {
    // Check if process is still running
    $status = proc_get_status($process);
    if (!$status['running']) {
        break;
    }

    // Process any available signals (if PCNTL is available)
    if (function_exists('pcntl_signal_dispatch')) {
        pcntl_signal_dispatch();
    }

    // Prepare streams for select
    $read = [STDIN, $pipes[1], $pipes[2]]; // stdin, process stdout, process stderr
    $write = [];
    $except = [];

    // Wait for activity on any stream (timeout after 1 second for signal processing)
    $activity = @stream_select($read, $write, $except, 1);

    if ($activity === false) {
        // Error occurred
        break;
    } elseif ($activity > 0) {
        // Check each stream that has activity
        foreach ($read as $stream) {
            $time = date('Y-m-d H:i:s');

            if ($stream === STDIN) {
                // Read from our stdin and forward to process stdin
                $input = fgets(STDIN, 8192);
                if ($input !== false && $input !== '') {
                    fwrite($logHandle, "{$time} [STDIN] {$input}"); // Log input
                    fflush($logHandle);
                    fwrite($pipes[0], $input);
                    fflush($pipes[0]);
                }
            } elseif ($stream === $pipes[1]) {
                // Read from process stdout and forward to our stdout
                $output = fgets($pipes[1], 8192);
                if ($output !== false && $output !== '') {
                    fwrite($logHandle, "{$time} [STDOUT] {$output}"); // Log output
                    fflush($logHandle);
                    fwrite(STDOUT, $output);
                    fflush(STDOUT);
                }
            } elseif ($stream === $pipes[2]) {
                // Read from process stderr and forward to our stderr
                $error = fgets($pipes[2], 8192);
                if ($error !== false && $error !== '') {
                    fwrite($logHandle, "{$time} [STDERR] {$error}"); // Log error
                    fflush($logHandle);
                    fwrite(STDERR, $error);
                    fflush(STDERR);
                }
            }
        }
    }
    // If $activity === 0, it was a timeout, which is fine for signal processing
}

// Clean up
foreach ($pipes as $pipe) {
    if (is_resource($pipe)) {
        fclose($pipe);
    }
}

// Get the exit code
$exitCode = proc_close($process);

// Exit with the same code as the subprocess
exit($exitCode);
