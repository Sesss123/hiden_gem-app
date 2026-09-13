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
            'style'       => ['required', 'string', 'max:40'],

            // Optional
            'destination' => ['nullable', 'string', 'max:100'],
            'origin'      => ['nullable', 'string', 'max:100'],
            'interests'   => ['nullable', 'array', 'max:10'],
            'interests.*' => ['string', 'max:50'],
            'from_lat'    => ['nullable', 'numeric', 'between:-90,90'],
            'from_lng'    => ['nullable', 'numeric', 'between:-180,180'],
            'start_date'  => ['nullable', 'date_format:Y-m-d'],
            'group_type'  => ['nullable', 'string', 'max:40'],
            'pace'        => ['nullable', 'string', 'max:40'],
            'transport_preference' => ['nullable', 'string', 'max:40'],
            'budget_lkr'  => ['nullable', 'numeric', 'min:0', 'max:10000000'],
            'constraints' => ['nullable', 'array', 'max:10'],
            'constraints.*' => ['string', 'max:100'],
            'must_include' => ['nullable', 'array', 'max:10'],
            'must_include.*' => ['string', 'max:100'],
            'avoid' => ['nullable', 'array', 'max:10'],
            'avoid.*' => ['string', 'max:100'],
            'language_code' => ['nullable', 'string', 'in:en,si,ta'],
            'user_context' => ['nullable', 'array'],
            'user_context.preferred_vibe' => ['nullable', 'string', 'max:50'],
            'user_context.memory_context' => ['nullable', 'array'],
            'user_context.memory_context.visited_recently' => ['nullable', 'array', 'max:5'],
            'user_context.memory_context.visited_recently.*' => ['string', 'max:100'],
            'user_context.memory_context.avoid_repeat_destinations' => ['nullable', 'boolean'],
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
