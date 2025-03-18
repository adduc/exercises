<?php

namespace App\Console\Commands;

use App\Models\Bookmark;
use Illuminate\Console\Command;

class Scratch extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:scratch';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Creating bookmark...');

        Bookmark::create([
            'Url' => 'http://example.com',
        ]);
    }
}
