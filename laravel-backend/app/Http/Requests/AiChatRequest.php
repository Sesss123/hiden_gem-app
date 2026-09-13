<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AiChatRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'prompt' => ['required', 'string', 'min:1', 'max:2000'],
            'use_rag' => ['sometimes', 'boolean'],
            'mode' => ['sometimes', 'string', 'in:default,analyst,optimizer,refactor,database,security'],
            'temperature' => ['sometimes', 'numeric', 'between:0,1'],
        ];
    }
}
