<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SampleJob implements ShouldQueue
{
    use Queueable;

    /**
     * Create a new job instance.
     */
    public function __construct(
        protected int $id
    ) {}

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        logger(__CLASS__, ['job' => $this]);
        dump((new \Exception)->getTraceAsString());
    }
}
