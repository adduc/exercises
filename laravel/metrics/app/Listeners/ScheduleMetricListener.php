<?php

namespace App\Listeners;

use Illuminate\Console\Events\ScheduledTaskFailed;
use Illuminate\Console\Events\ScheduledTaskFinished;
use Illuminate\Console\Events\ScheduledTaskStarting;
use Illuminate\Console\Scheduling\CallbackEvent;
use Illuminate\Support\Facades\Log;

use function Illuminate\Support\php_binary;

/**
 * This listener is triggered before and after a job is processed, and
 * is used to measure the time and approximate CPU usage of the job.
 */
class ScheduleMetricListener
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
    public function handle(ScheduledTaskStarting|ScheduledTaskFinished|ScheduledTaskFailed $event): void
    {
        $id = spl_object_id($event->task);
        $usage = $this->measureUsage($event);

        if ($event instanceof ScheduledTaskStarting) {
            static::$events[$id] = $usage;
        } elseif ($event instanceof ScheduledTaskFinished || $event instanceof ScheduledTaskFailed) {
            if (!isset(static::$events[$id])) {
                return;
            }

            $start = static::$events[$id];

            Log::channel('metrics')->info('Schedule', [
                'command' => $this->buildCommandName($event),
                'status' => $event instanceof ScheduledTaskFinished ? 'finished' : 'failed',
                'time_ms' => number_format(($usage['time'] - $start['time']) * 1000, 3),
                'cpu_time' => $usage['cpu_time'] - $start['cpu_time'],
            ]);
        }
    }

    protected function buildCommandName(ScheduledTaskFinished|ScheduledTaskFailed $event): string
    {
        // Provide context when the task is a callback
        if ($event->task instanceof CallbackEvent) {
            $callable = (new \ReflectionObject($event->task))
                ->getProperty('callback')
                ->getValue($event->task);

            $reflect = new \ReflectionFunction($callable);

            return sprintf(
                'Callable(%s:%s)',
                str_replace(base_path('/'), '', $reflect->getFileName()),
                $reflect->getStartLine()
            );
        }

        $command = $event->task->command;

        $command = str_replace(php_binary(), '@php', $command);

        return $command;
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
            'task' => $event->task,
        ];
    }
}
