<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class QueryRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        // ensure the example parameter is only ever provided via query string
        $this->request->remove('example');
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'example' => 'required|string',
        ];
    }
}
