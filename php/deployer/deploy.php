<?php

declare(strict_types=1);

namespace Deployer;

require 'recipe/common.php';

// Config

// if the PHP configuration variables_order excludes e, $_ENV won't be
// populated, so we check if it's empty and then use getenv() to fill it
if (empty($_ENV)) {
    $_ENV = getenv();
}

set('repository', '');

add('shared_files', []);
add('shared_dirs', []);
add('writable_dirs', []);

set('shell', '/bin/sh');

// Hosts

host($_ENV['DEPLOY_HOST'])
    ->set('port', $_ENV['DEPLOY_PORT'] ?? 22)
    ->set('remote_user', $_ENV['DEPLOY_USER'])
    ->set('deploy_path', $_ENV['DEPLOY_PATH']);

// Hooks

after('deploy:failed', 'deploy:unlock');

// Overrides

task('deploy:update_code')->setCallback(static function () {
    upload('.', '{{release_path}}', [
        'options' => [
            '--exclude=.git',
            '--exclude=deploy.php',
            '--exclude=node_modules',
        ],
    ]);
});
