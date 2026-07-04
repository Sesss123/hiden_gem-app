<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * [BUG-Q006 / BUG-Q010] PlanItineraryRequest
 *
 * Validates and sanitises the request payload before it is forwarded
 * to the Python AI subsystem.  Raw user input MUST NOT be forwarded
 * without validation (OWASP A03: Injection).
 */
class PlanItineraryRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Auth is already enforced by the Sanctum middleware on the route.
        return true;
    }

    public function rules(): array
    {
        return [
            // Required
            'days'        => ['required', 'integer', 'min:1', 'max:30'],
            'style'       => ['required', 'string', 'in:adventure,culture,chill,balanced,nature,family,budget'],

            // Optional
            'destination' => ['nullable', 'string', 'max:100'],
            'origin'      => ['nullable', 'string', 'max:100'],
            'interests'   => ['nullable', 'array', 'max:10'],
            'interests.*' => ['string', 'max:50'],
            'transport'   => ['nullable', 'string', 'in:bus,train,car,tuk,mixed'],
            'budget'      => ['nullable', 'numeric', 'min:0', 'max:1000000'],
        ];
    }

    public function messages(): array
    {
        return [
            'days.required'    => 'Trip duration (days) is required.',
            'days.integer'     => 'Trip duration must be a whole number.',
            'days.max'         => 'Maximum trip duration is 30 days.',
            'style.required'   => 'A travel style (e.g. adventure, culture) is required.',
            'style.in'         => 'The selected travel style is not valid.',
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
