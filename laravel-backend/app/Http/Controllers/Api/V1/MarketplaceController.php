<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class MarketplaceController extends Controller
{
    public function search(Request $request, FirestoreService $firestore)
    {
        $validated = $request->validate([
            'q' => 'required|string|min:2|max:100',
            'region' => 'nullable|string|max:100',
            'category' => 'nullable|string|max:100',
            'language' => 'nullable|string|max:100',
            'vehicle' => 'nullable|boolean',
            'tour_type' => 'nullable|in:doesBoatSafari,doesWildlifeSafari,doesHiking,doesDiving,doesCulturalTours',
            'page' => 'nullable|integer|min:1|max:500',
        ]);

        $needle = mb_strtolower(trim($validated['q']));
        $all = $firestore->listDocuments('guide_listings');
        $filtered = array_values(array_filter($all, function ($listing) use ($validated, $needle) {
            if (($listing['status'] ?? '') !== 'published' || ($listing['moderationStatus'] ?? '') !== 'approved') return false;
            $haystack = mb_strtolower(implode(' ', array_filter([
                $listing['displayName'] ?? '', $listing['bio'] ?? '', $listing['guideCategory'] ?? '',
                implode(' ', $listing['regions'] ?? []), implode(' ', $listing['languages'] ?? []),
                implode(' ', $listing['specializations'] ?? []),
            ])));
            if (!str_contains($haystack, $needle)) return false;
            if (!empty($validated['region']) && !in_array($validated['region'], $listing['regions'] ?? [], true)) return false;
            if (!empty($validated['category']) && ($listing['guideCategory'] ?? null) !== $validated['category']) return false;
            if (!empty($validated['language']) && !in_array($validated['language'], $listing['languages'] ?? [], true)) return false;
            if (($validated['vehicle'] ?? false) && ($listing['vehicleAvailable'] ?? false) !== true) return false;
            if (!empty($validated['tour_type']) && ($listing[$validated['tour_type']] ?? false) !== true) return false;
            return true;
        }));
        usort($filtered, fn ($a, $b) => ($b['ratingAverage'] ?? 0) <=> ($a['ratingAverage'] ?? 0));

        $page = (int) ($validated['page'] ?? 1);
        $perPage = 20;
        $offset = ($page - 1) * $perPage;
        $items = array_slice($filtered, $offset, $perPage);
        return response()->json([
            'listings' => $items,
            'has_more' => $offset + count($items) < count($filtered),
            'next_page' => $offset + count($items) < count($filtered) ? $page + 1 : null,
        ]);
    }

    public function featured(FirestoreService $firestore)
    {
        $listings = Cache::remember('listings_featured', 300, function () use ($firestore) {
            $all = $firestore->queryDocuments('guide_listings', 'isFeatured', 'EQUAL', true);
            $filtered = array_values(array_filter($all, fn ($listing) =>
                ($listing['status'] ?? '') === 'published' && ($listing['moderationStatus'] ?? '') === 'approved'
            ));
            usort($filtered, fn ($a, $b) => ($b['ratingAverage'] ?? 0) <=> ($a['ratingAverage'] ?? 0));
            return array_slice($filtered, 0, 10);
        });

        return response()->json(['listings' => $listings]);
    }
}
