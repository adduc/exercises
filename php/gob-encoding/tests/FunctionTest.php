<?php

declare(strict_types=1);

namespace Adduc\Encoding\Gob;

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

final class FunctionTest extends TestCase
{
    #[DataProvider('providesToInt')]
    public function testToInt(int $input, int $expected): void
    {
        $this->assertEquals($expected, toInt($input));
    }

    public static function providesToInt(): array
    {
        return [
            [0x00, 0],
            [0x62, 49],
            [0x63, -50],
            [0x7F, -64],
            [0xFF, -128],
        ];
    }
}
