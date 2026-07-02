<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\PlaceImage;
use App\Services\ImageProcessingService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PlaceController extends Controller
{
    protected $imageService;

    public function __construct(ImageProcessingService $imageService)
    {
        $this->imageService = $imageService;
    }

    public function index(Request $request)
    {
        $query = Place::with('coverImage')->where('is_deleted', false);

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('district', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($category = $request->input('category')) {
            $query->where('category', $category);
        }

        $places = $query->orderBy('updated_at', 'desc')->paginate(15);
        return view('admin.places.index', compact('places'));
    }

    public function create()
    {
        return view('admin.places.form', ['place' => new Place()]);
    }

    public function store(Request $request)
    {
        $data = $this->validatePlace($request);
        if (empty($data['id'])) {
            $data['id'] = $this->generateSmartId($data['category'] ?? 'General', $data['district'] ?? 'SL');
        }

        // Creating will trigger PlaceObserver::saving to stamp sync_version
        $place = Place::create($data);

        $this->handleImages($request, $place);

        return redirect()->route('admin.places.index')->with('success', "Place '{$place->name}' created successfully.");
    }

    public function edit($id)
    {
        $place = Place::with('images')->findOrFail($id);
        return view('admin.places.form', compact('place'));
    }

    public function update(Request $request, $id)
    {
        $place = Place::findOrFail($id);
        $data = $this->validatePlace($request, true);

        // Updating triggers PlaceObserver::saving if dirty
        $place->update($data);

        $this->handleImages($request, $place);

        return redirect()->route('admin.places.index')->with('success', "Place '{$place->name}' updated successfully.");
    }

    public function destroy($id)
    {
        $place = Place::findOrFail($id);
        // Intercepted by PlaceObserver::deleting -> soft deletes and increments sync_version!
        $place->delete();

        return redirect()->route('admin.places.index')->with('success', "Place '{$place->name}' moved to trash (soft deleted).");
    }

    public function deleteImage($imageId)
    {
        $image = PlaceImage::findOrFail($imageId);
        // Deleting image touches parent place -> increments sync_version!
        $image->delete();

        return back()->with('success', 'Image removed.');
    }

    public function setCoverImage($imageId)
    {
        $image = PlaceImage::findOrFail($imageId);
        PlaceImage::where('place_id', $image->place_id)->update(['is_cover' => false]);
        $image->update(['is_cover' => true]);

        return back()->with('success', 'Cover image updated.');
    }

    protected function validatePlace(Request $request, $isUpdate = false)
    {
        return $request->validate([
            'id' => $isUpdate ? 'nullable' : 'nullable|string|unique:places,id',
            'name' => 'required|string|max:255',
            'district' => 'required|string|max:100',
            'category' => 'required|string|max:100',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'rating' => 'nullable|numeric|between:0,5',
            'ticket_range' => 'nullable|string|max:100',
            'road_type' => 'nullable|string|max:100',
            'vehicle_access' => 'nullable|string|max:100',
            'parking_range' => 'nullable|string|max:100',
            'best_time' => 'nullable|string|max:100',
            'best_time_to_visit' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'province' => 'nullable|string|max:100',
            'opening_hours' => 'nullable|string|max:255',
            'mobile_signal' => 'nullable|string|max:100',
            'activities' => 'nullable|string',
            'tourist_popularity' => 'nullable|string|max:100',
            'family_friendly' => 'nullable|string|max:50',
            'budget_category' => 'nullable|string|max:100',
            'ticket_price' => 'nullable|string|max:100',
            'parking_avail' => 'nullable|string|max:50',
            'toilets' => 'nullable|string|max:50',
            'food_nearby' => 'nullable|string|max:50',
            'wheelchair_access' => 'nullable|string|max:50',
            'camping_allowed' => 'nullable|string|max:50',
            'safety_level' => 'nullable|string|max:100',
            'wildlife_hazard' => 'nullable|string|max:100',
            'guide_required' => 'nullable|string|max:50',
            'rain_sensitivity' => 'nullable|string|max:100',
            'monsoon_note' => 'nullable|string|max:255',
            'height_m' => 'nullable|string|max:50',
            'length_km' => 'nullable|string|max:50',
            'surfing' => 'nullable|string|max:50',
            'road_condition' => 'nullable|string|max:100',
            'ar_supported' => 'nullable|boolean',
            'ar_tier' => 'nullable|integer',
            'ar_brand_name' => 'nullable|string|max:100',
            'ar_model_url' => 'nullable|string|max:500',
            'ar_historical_model_url' => 'nullable|string|max:500',
            'ar_model_scale' => 'nullable|numeric',
            'historical_period' => 'nullable|string|max:100',
            'ar_file_size_mb' => 'nullable|numeric',
            'audio_guide_url_si' => 'nullable|string|max:500',
            'audio_guide_url_en' => 'nullable|string|max:500',
            'geohash' => 'nullable|string|max:20',
            'access_tier' => 'nullable|string|in:Free,PRO,VIP',
        ]);
    }

    protected function handleImages(Request $request, Place $place)
    {
        if ($request->hasFile('images')) {
            $order = $place->images()->max('sort_order') ?: 0;
            $isFirst = $place->images()->count() === 0;

            foreach ($request->file('images') as $file) {
                $paths = $this->imageService->processAndStore($file, $place->id);
                $order++;

                PlaceImage::create([
                    'place_id' => $place->id,
                    'thumb_path' => $paths['thumb_path'],
                    'full_path' => $paths['full_path'],
                    'is_cover' => $isFirst && $order === 1,
                    'sort_order' => $order,
                ]);
            }
        }
    }

    protected function generateSmartId($category, $district)
    {
        $catMap = [
            'waterfalls' => 'WF',
            'beach' => 'BE',
            'religious places' => 'TM',
            'temple' => 'TM',
            'sacred temple' => 'TM',
            'view point' => 'VP',
            'tea estate' => 'TE',
            'adventure park' => 'AP',
            'ancient architecture' => 'ARC',
            'colonial fort' => 'CF',
            'royal palace' => 'RP',
            'historical monument' => 'HM',
            'wildlife / national park' => 'WL',
            'hiking / trekking' => 'HK',
            'village experience' => 'VE',
            'culinary / food' => 'FD',
            'cultural site' => 'CS',
        ];

        $catKey = strtolower(trim($category));
        $catCode = $catMap[$catKey] ?? strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $category), 0, 3));
        if (empty($catCode)) $catCode = 'GEM';

        $distCode = strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $district), 0, 3));
        if (empty($distCode)) $distCode = 'SL';

        $prefix = "{$catCode}-{$distCode}-";
        
        $lastPlace = Place::where('id', 'like', "{$prefix}%")
            ->orderBy('id', 'desc')
            ->first();

        $nextNum = 1;
        if ($lastPlace && preg_match('/-(\d+)$/', $lastPlace->id, $matches)) {
            $nextNum = ((int)$matches[1]) + 1;
        }

        return $prefix . sprintf('%03d', $nextNum);
    }
}
