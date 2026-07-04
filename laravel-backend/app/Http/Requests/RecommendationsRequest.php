<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * [BUG-Q006 / BUG-Q010] RecommendationsRequest
 *
 * Validates and sanitises the recommendation request payload before it
 * is forwarded to the Python AI subsystem.
 */
class RecommendationsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // Required
            'lat'   => ['required', 'numeric', 'between:-90,90'],
            'lng'   => ['required', 'numeric', 'between:-180,180'],

            // Optional
            'vibe'         => ['nullable', 'string', 'max:100'],
            'limit'        => ['nullable', 'integer', 'min:1', 'max:20'],
            'district'     => ['nullable', 'string', 'max:100'],
            'categories'   => ['nullable', 'array', 'max:10'],
            'categories.*' => ['string', 'max:50'],
        ];
    }

    public function messages(): array
    {
        return [
            'lat.required' => 'Latitude is required.',
            'lat.between'  => 'Latitude must be between -90 and 90.',
            'lng.required' => 'Longitude is required.',
            'lng.between'  => 'Longitude must be between -180 and 180.',
        ];
    }

    /**
     * Return a structured JSON error instead of a redirect on validation failure.
     * BUG-Q011: Raw validation exception messages must not expose internal field names.
     */
    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'status'  => 'error',
            'message' => 'Invalid request parameters.',
            'errors'  => $validator->errors(),
        ], 422));
    }
}
