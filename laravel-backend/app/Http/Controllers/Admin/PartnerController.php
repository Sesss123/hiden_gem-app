<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Manages the Firestore `partners` collection — boutique stays/cafes shown
 * in the app's "Nearby Partners" (AR viewer) feature and, when flagged with
 * a discount, the tourist-facing "Curator Deals" premium benefit.
 *
 * No MySQL table backs this — `partners` was already Firestore-only and
 * unused before this controller (firestore.rules had it stubbed with no
 * writer). Reads/writes go straight through FirestoreService with the
 * service account, same as GuideController's Firestore-facing actions.
 */
class PartnerController extends Controller
{
    public function index(Request $request, FirestoreService $firestore)
    {
        $partners = $firestore->listDocuments('partners');

        if ($search = $request->input('search')) {
            $needle = strtolower($search);
            $partners = array_values(array_filter($partners, function ($p) use ($needle) {
                return str_contains(strtolower($p['name'] ?? ''), $needle)
                    || str_contains(strtolower($p['category'] ?? ''), $needle);
            }));
        }

        usort($partners, fn ($a, $b) => strcmp($a['name'] ?? '', $b['name'] ?? ''));

        return view('admin.partners.index', compact('partners'));
    }

    public function create()
    {
        return view('admin.partners.form', ['partner' => null]);
    }

    public function store(Request $request, FirestoreService $firestore)
    {
        $data = $this->validatePartner($request);
        $id = Str::slug($data['name']) . '-' . Str::random(6);

        $firestore->patchDocument('partners', $id, $data);

        return redirect()->route('admin.partners.index')->with('success', "Partner '{$data['name']}' created successfully.");
    }

    public function edit($id, FirestoreService $firestore)
    {
        $partner = $firestore->getDocument('partners', $id);
        abort_if($partner === null, 404);

        return view('admin.partners.form', compact('partner'));
    }

    public function update(Request $request, $id, FirestoreService $firestore)
    {
        $data = $this->validatePartner($request);
        $firestore->patchDocument('partners', $id, $data);

        return redirect()->route('admin.partners.index')->with('success', "Partner '{$data['name']}' updated successfully.");
    }

    public function destroy($id, FirestoreService $firestore)
    {
        $firestore->deleteDocument('partners', $id);

        return redirect()->route('admin.partners.index')->with('success', 'Partner removed.');
    }

    protected function validatePartner(Request $request): array
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'required|string|in:hotel,guide,cafe,artisan',
            'description' => 'nullable|string',
            'imageUrl' => 'nullable|string|max:1000',
            'rating' => 'nullable|numeric|between:0,5',
            'priceRange' => 'nullable|string|max:20',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'bookingUrl' => 'nullable|string|max:1000',
            'isVerified' => 'nullable|boolean',
            'isPremiumDeal' => 'nullable|boolean',
            'discountPercent' => 'nullable|integer|between:0,100',
            'dealDescription' => 'nullable|string|max:500',
            'dealValidUntil' => 'nullable|date',
        ]);

        $data['isVerified'] = $request->boolean('isVerified');
        $data['isPremiumDeal'] = $request->boolean('isPremiumDeal');
        $data['rating'] = (float) ($data['rating'] ?? 4.0);
        $data['priceRange'] = $data['priceRange'] ?? '$$';
        $data['discountPercent'] = (int) ($data['discountPercent'] ?? 0);
        $data['dealDescription'] = $data['dealDescription'] ?? '';
        if (!empty($data['dealValidUntil'])) {
            $data['dealValidUntil'] = \Carbon\Carbon::parse($data['dealValidUntil'])->toIso8601String();
        } else {
            unset($data['dealValidUntil']);
        }

        return $data;
    }
}
