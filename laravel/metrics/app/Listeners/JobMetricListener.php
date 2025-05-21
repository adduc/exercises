<?php

namespace App\Listeners;

use Illuminate\Queue\Events\JobAttempted;
use Illuminate\Queue\Events\JobProcessing;
use Illuminate\Support\Facades\Log;

/**
 * This listener is triggered before and after a job is processed, and
 * is used to measure the time and approximate CPU usage of the job.
 */
class JobMetricListener
{
    /** <spl_object_id> => [<dispatch_time>, <cpu_use>] */
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
    public function handle(JobProcessing|JobAttempted $event): void
    {
        $id = spl_object_id($event->job);
        $usage = $this->measureUsage($event);

        if ($event instanceof JobProcessing) {
            static::$events[$id] = $usage;
        } elseif ($event instanceof JobAttempted) {
            if (!isset(static::$events[$id])) {
                return;
            }

            $start = static::$events[$id];

            Log::channel('metrics')->info('Job', [
                'job' => get_class($event->job),
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
            'job' => $event->job,
        ];
    }
}
