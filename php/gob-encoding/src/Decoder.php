<?php

declare(strict_types=1);

namespace Adduc\Encoding\Gob;

use Exception;

class Decoder
{
    protected string $buf = '';

    public function __construct(
        protected $r
    ) {}

    public function decode(&$e): void
    {
        $this->decodeValue($e);
    }

    public function decodeValue(&$e): void
    {
        rewind($this->r);

        $id = $this->decodeTypeSequence(false);

        throw new Exception('Not implemented');
    }

    protected function decodeTypeSequence(bool $isInterface): TypeId
    {
        $firstMessage = true;
        while (true) {
            if (strlen($this->buf) === 0) {
                if (!$this->recvMessage()) {
                    if (!$firstMessage && feof($this->r)) {
                        throw new UnexpectedEOF();
                    }
                }
            }

            $id = $this->nextInt();
        }

        throw new Exception('Not implemented');
    }

    protected function recvMessage(): bool
    {
        throw new Exception('Not implemented');
    }

    protected function nextInt(): int
    {
        throw new Exception('Not implemented');
    }
}

class TypeId {}

class UnexpectedEOF extends Exception {}
