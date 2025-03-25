<?php declare(strict_types=1);

namespace Adduc\Encoding\Gob;

const UINT64_SIZE = 8;

/**
 * Turns an encoded int into an int, according to golang's marshaling
 * rules.
 */
function toInt (int $x): int {
    $i = $x >> 1;
    return ($x & 1) ? ~$i : $i;
};

function decodeUintReader($r): array {
    $width = 1;
    $buf = fread($r, $width);
    if ($buf === false) {
        return [null, $width];
    }
    if ($buf <= 0x7f) {
        return [(int) $buf, $width];
    }
    $buf = -1 * $buf;
}