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
        $this->info('Finding bookmark...');

        $bookmark = Bookmark::where('url', 'http://example.com')->first();


        if (!$bookmark) {
            $this->info('Bookmark not found, creating...');

            $bookmark = Bookmark::create([
                'url' => 'http://example.com',
            ]);
        }

        $this->info('Bookmark attributes:');
        dump($bookmark->toArray());

        $this->info('Updating bookmark...');
        $bookmark->touch();
        $bookmark->save();

        dd($bookmark->toArray());
    }
}
