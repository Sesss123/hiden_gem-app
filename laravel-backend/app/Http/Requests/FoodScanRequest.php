<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class FoodScanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // 8 MB encoded ceiling; Python also validates decoded/decompressed size.
            'image_base64' => ['required', 'string', 'max:8000000'],
            'user_mode' => ['sometimes', 'string', 'in:Tourist,normal,weight_loss,muscle_gain,diabetic'],
            'spice_preference' => ['sometimes', 'string', 'in:Mild,Medium,Hot'],
            'compressed' => ['sometimes', 'boolean'],
        ];
    }
}
