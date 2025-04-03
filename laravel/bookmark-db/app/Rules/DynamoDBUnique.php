<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class DynamoDBUnique implements ValidationRule
{
    public function __construct(
        protected string $model,
        protected ?string $column = null,
    ) {
    }

    /**
     * Run the validation rule.
     *
     * @param  \Closure(string, ?string=): \Illuminate\Translation\PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {

        $model = $this->model;
        $column = $this->column ?? $attribute;
        $exists = $model::where($column, $value)->first();

        if ($exists) {
            $fail('validation.unique')->translate([
                'attribute' => $attribute,
            ]);
        }
    }
}
