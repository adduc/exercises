<?php declare(strict_types=1);

namespace Adduc\Encoding\Gob;

/**
 * Turns an encoded int into an int, according to golang's marshaling
 * rules.
 */
function toInt (int $x): int {
    $i = $x >> 1;
    return ($x & 1) ? ~$i : $i;
};