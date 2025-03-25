<?php

declare(strict_types=1);

namespace Adduc\Encoding\Gob;

use PHPUnit\Framework\TestCase;

final class DecoderTest extends TestCase
{
    public function testDecode()
    {
        $fh = fopen('/dev/null', 'rb');
        $decoder = new Decoder($fh);
        $decoder->decode($a);
    }
}
