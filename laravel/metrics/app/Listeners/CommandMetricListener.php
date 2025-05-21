<?php

namespace App\Listeners;

use Illuminate\Console\Events\CommandFinished;
use Illuminate\Console\Events\CommandStarting;
use Illuminate\Console\Events\ScheduledTaskFailed;
use Illuminate\Console\Events\ScheduledTaskFinished;
use Illuminate\Console\Events\ScheduledTaskStarting;
use Illuminate\Console\Scheduling\CallbackEvent;
use Illuminate\Support\Facades\Log;

/**
 * This listener is triggered before and after a job is processed, and
 * is used to measure the time and approximate CPU usage of the job.
 */
class CommandMetricListener
{
    /** <int> => [<dispatch_time>, <cpu_use>] */
    protected static array $events = [];

    /**
     * Create the event listener.
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     */
    public function handle(CommandStarting|CommandFinished $event): void
    {
        $id = crc32($event->command . spl_object_id($event->input) . spl_object_id($event->output));
        $usage = $this->measureUsage($event);

        if ($event instanceof CommandStarting) {
            static::$events[$id] = $usage;
        } elseif ($event instanceof CommandFinished) {
            if (!isset(static::$events[$id])) {
                return;
            }

            $start = static::$events[$id];

            Log::channel('metrics')->info('Command', [
                'command' => $event->command,
                'time_ms' => number_format(($usage['time'] - $start['time']) * 1000, 3),
                'cpu_time' => $usage['cpu_time'] - $start['cpu_time'],
            ]);
        }
    }

    protected function measureUsage($event): array
    {
        $time = microtime(true);
        $r_usage = getrusage();
        $cpu_time = array_sum([
            $r_usage['ru_utime.tv_sec'] * 1000000,
            $r_usage['ru_utime.tv_usec'],
            $r_usage['ru_stime.tv_sec'] * 1000000,
            $r_usage['ru_stime.tv_usec'],
        ]);
        return [
            'time' => $time,
            'cpu_time' => $cpu_time,
        ];
    }
}
