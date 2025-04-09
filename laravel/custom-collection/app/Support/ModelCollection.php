<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Collection;

class ModelCollection extends Collection
{
    public function loadMissingCount($relations): static
    {
        if ($this->isEmpty()) {
            // nothing to load
            return $this;
        }

        if (is_string($relations)) {
            $relations = func_get_args();
        }

        $to_load = [];

        foreach ($relations as $value) {
            if (!$this->first()->hasAttribute($value . '_count')) {
                $to_load[] = $value;
            }
        }

        return $this->loadCount($to_load);
    }
}
