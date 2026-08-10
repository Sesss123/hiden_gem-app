@extends('admin.layout')

@section('content')
@php
    $isEdit = $place->exists;
    $action = $isEdit ? route('admin.places.update', $place->id) : route('admin.places.store');
@endphp

<div class="max-w-4xl mx-auto space-y-6">
    <div class="flex items-center justify-between">
        <div>
            <a href="{{ route('admin.places.index') }}" class="text-xs font-semibold text-slate-400 hover:text-white transition flex items-center gap-1 mb-1">
                <i class="fa-solid fa-arrow-left"></i> Back to Gems List
            </a>
            <h2 class="text-2xl font-bold text-white flex items-center gap-2">
                <i class="fa-solid {{ $isEdit ? 'fa-pen-to-square' : 'fa-circle-plus' }} text-emerald-400"></i>
                {{ $isEdit ? 'Edit Gem: ' . $place->name : 'Create New Hidden Gem' }}
            </h2>
        </div>
        @if($isEdit)
            <span class="text-xs bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-xl font-mono text-teal-300">
                Current Sync Version: v{{ $place->sync_version }}
            </span>
        @endif
    </div>

    @if ($errors->any())
        <div class="glass-card p-4 rounded-2xl border border-red-500/30 bg-red-500/5">
            <p class="text-xs font-semibold text-red-400 mb-1 flex items-center gap-2">
                <i class="fa-solid fa-triangle-exclamation"></i> Please fix the following before saving:
            </p>
            <ul class="text-xs text-red-300 list-disc list-inside space-y-0.5">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <!-- Tab bar -->
    <div class="glass-card p-2 rounded-2xl border border-slate-800 sticky top-2 z-10 backdrop-blur">
        <div class="flex gap-1 overflow-x-auto" id="form_tabs" role="tablist">
            <button type="button" data-tab="core" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-tag"></i> Core Info
            </button>
            <button type="button" data-tab="gps" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-earth-asia"></i> GPS
            </button>
            <button type="button" data-tab="insights" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-compass"></i> Travel Insights
            </button>
            <button type="button" data-tab="access" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-shield-halved"></i> Access & Safety
            </button>
            <button type="button" data-tab="ar" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-cube"></i> AR & Audio
            </button>
            <button type="button" data-tab="media" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-images"></i> Media
            </button>
        </div>
    </div>

    <form id="place_form" action="{{ $action }}" method="POST" enctype="multipart/form-data" class="space-y-6">
        @csrf
        @if($isEdit)
            @method('PUT')
        @endif

        <!-- Tab 1: Core Identification -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="core">
            <h3 class="text-sm font-semibold text-emerald-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-tag"></i> Core Identification
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Custom Gem ID (Optional)</label>
                    <input type="text" name="id" id="gem_id_input" value="{{ old('id', $place->id) }}" {{ $isEdit ? 'readonly' : '' }}
                        placeholder="e.g. WF-MAT-001"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 {{ $isEdit ? 'opacity-60 cursor-not-allowed' : '' }}">
                </div>
                <div class="md:col-span-2">
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Place Name *</label>
                    <input type="text" name="name" value="{{ old('name', $place->name) }}" required
                        placeholder="e.g. Sigiriya Rock Fortress"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500 font-semibold">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">District *</label>
                    @php
                        $defaultDists = ['Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Moneragala', 'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya'];
                        $dbDists = \App\Models\Place::select('district')->distinct()->pluck('district')->toArray();
                        $allDists = array_unique(array_merge($defaultDists, $dbDists));
                        sort($allDists);
                    @endphp
                    <select name="district" id="district_input" required class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select District</option>
                        @foreach($allDists as $dist)
                            @if($dist)
                                <option value="{{ $dist }}" {{ old('district', $place->district) == $dist ? 'selected' : '' }}>{{ $dist }}</option>
                            @endif
                        @endforeach
                    </select>
                    <input type="hidden" name="province" id="province_input" value="{{ old('province', $place->province) }}">
                    <p class="text-[11px] text-slate-500 mt-1">Province: <span id="province_display" class="text-slate-300 font-medium">{{ old('province', $place->province) ?: '—' }}</span></p>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Category *</label>
                    @php
                        $defaultCats = [
                            'Adventure Park', 'Religious Places', 'Temple', 'Beach', 'Tea Estate', 'View Point', 'Waterfalls',
                            'Ancient Architecture', 'Colonial Fort', 'Royal Palace', 'Sacred Temple', 'Natural Heritage',
                            'Historical Monument', 'Wildlife / National Park', 'Hiking / Trekking', 'Village Experience',
                            'Culinary / Food', 'Cultural Site',
                            'Eco Tourism', 'Scenic Train Journeys', 'Cycling Tours', 'Kayaking & Canoeing', 'Fishing Tourism',
                            'Shopping Tourism', 'Festival & Event Tourism', 'Gem & Jewelry Tourism', 'Water Sports',
                            'Surfing Tourism', 'Sunrise & Sunset Viewpoints', 'River & Lagoon Tours', 'Museum Tourism',
                            'Multi-Religious Pilgrimage', 'Film & Photography Locations', 'Honeymoon & Romantic Getaways',
                            'Luxury Tourism', 'Business & MICE Tourism',
                            'General',
                        ];
                        $dbCats = \App\Models\Place::select('category')->distinct()->pluck('category')->toArray();
                        $allCats = array_unique(array_merge($defaultCats, $dbCats));
                        sort($allCats);
                    @endphp
                    <select name="category" id="category_input" required class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Category</option>
                        @foreach($allCats as $cat)
                            @if($cat)
                                <option value="{{ $cat }}" {{ old('category', $place->category) == $cat ? 'selected' : '' }}>{{ $cat }}</option>
                            @endif
                        @endforeach
                    </select>
                </div>
            </div>
        </div>

        <!-- Tab 2: Location Coordinates & GPS -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="gps">
            <h3 class="text-sm font-semibold text-teal-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-earth-asia"></i> GPS Coordinates & Geohash
            </h3>

            <div>
                <label class="block text-xs font-semibold text-slate-300 mb-1">Paste a Google Maps Link</label>
                <p class="text-[11px] text-slate-500 mb-2">Paste a link copied from Google Maps' "Share" button — Latitude and Longitude below fill in automatically. Coordinates can still be typed or adjusted manually after.</p>
                <div class="flex gap-2">
                    <input type="text" id="maps_link_input" placeholder="e.g. https://maps.google.com/?q=7.957,80.7603 or https://www.google.com/maps/@7.957,80.7603,15z"
                        class="flex-1 px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                    <button type="button" id="maps_link_parse_btn" class="px-4 py-2 rounded-xl bg-slate-800 hover:bg-emerald-600 text-slate-300 hover:text-white text-xs font-semibold transition shrink-0">
                        <i class="fa-solid fa-location-crosshairs mr-1"></i> Fill Coordinates
                    </button>
                </div>
                <p id="maps_link_status" class="text-[11px] mt-1.5 hidden"></p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Latitude (Decimal) *</label>
                    <input type="number" step="0.0000001" name="lat" id="lat_input" value="{{ old('lat', $place->lat) }}" required
                        placeholder="e.g. 7.9570000"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Longitude (Decimal) *</label>
                    <input type="number" step="0.0000001" name="lng" id="lng_input" value="{{ old('lng', $place->lng) }}" required
                        placeholder="e.g. 80.7603000"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Geohash</label>
                    <input type="text" value="{{ $place->geohash }}" readonly
                        placeholder="Auto-computed on save"
                        class="w-full px-3 py-2 bg-slate-900/60 border border-slate-800 rounded-xl text-xs text-slate-400 font-mono cursor-not-allowed focus:outline-none">
                    <p class="text-[10px] text-slate-500 mt-1">Derived automatically from Latitude/Longitude when you save — not editable.</p>
                </div>
            </div>

            @if(old('lat', $place->lat) && old('lng', $place->lng))
                <div id="map_preview_link" class="text-[11px]">
                    <a href="https://www.google.com/maps?q={{ old('lat', $place->lat) }},{{ old('lng', $place->lng) }}" target="_blank" rel="noopener"
                        class="text-teal-400 hover:text-teal-300 inline-flex items-center gap-1">
                        <i class="fa-solid fa-arrow-up-right-from-square"></i> Preview this location on Google Maps
                    </a>
                </div>
            @endif
        </div>

        <!-- Tab 3: Curated Travel Insights & Details -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="insights">
            <h3 class="text-sm font-semibold text-amber-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-compass"></i> Curated Travel Insights & Details (App Unique Value)
            </h3>

            <div class="grid grid-cols-1 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Description</label>
                    <textarea name="description" rows="3" placeholder="Detailed story and religious/cultural background of the gem..."
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">{{ old('description', $place->description) }}</textarea>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Opening Hours</label>
                    @php
                        $openOpts = ['24 Hours', '8 AM - 5 PM', '8 AM - 6 PM', 'Varies by season'];
                        $currOpen = old('opening_hours', $place->opening_hours);
                    @endphp
                    <select name="opening_hours" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Hours</option>
                        @foreach($openOpts as $opt)
                            <option value="{{ $opt }}" {{ $currOpen == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currOpen && !in_array($currOpen, $openOpts))
                            <option value="{{ $currOpen }}" selected>{{ $currOpen }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Best Time to Visit</label>
                    <input type="text" name="best_time_to_visit" value="{{ old('best_time_to_visit', $place->best_time_to_visit ?: $place->best_time) }}"
                        placeholder="e.g. Dec to Apr, Apr-Sep"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Tourist Popularity</label>
                    @php
                        $popOpts = ['Very High', 'High', 'Medium', 'Low'];
                        $currPop = old('tourist_popularity', $place->tourist_popularity);
                    @endphp
                    <select name="tourist_popularity" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Popularity</option>
                        @foreach($popOpts as $opt)
                            <option value="{{ $opt }}" {{ $currPop == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currPop && !in_array($currPop, $popOpts))
                            <option value="{{ $currPop }}" selected>{{ $currPop }} (Custom)</option>
                        @endif
                    </select>
                </div>
            </div>

            <div>
                <label class="block text-xs font-semibold text-slate-300 mb-2">Activities</label>
                <p class="text-[11px] text-slate-500 mb-2">Showing activities relevant to the selected category. Pick a category above to refine this list.</p>
                @php
                    // group => [keywords to match against category text, activity list]
                    // keywords are matched case-insensitively as substrings, so
                    // messy variants like "Temple/Stupa" or "Sandy Beach (Kitesurf)" still hit.
                    $activityGroups = [
                        'religious' => [
                            'keywords' => ['temple', 'kovil', 'mosque', 'church', 'shrine', 'devale', 'devalaya', 'stupa', 'monastery', 'sanctuary', 'basilica', 'chapel', 'cathedral'],
                            'activities' => ['Prayer and Meditation', 'Photography', 'Reflection', 'Cultural Tours', 'Historical Tours', 'Nature Walk'],
                        ],
                        'waterfall' => [
                            'keywords' => ['cascade', 'plunge', 'waterfall', 'fall', 'horsetail', 'tiered', 'segmented', 'fan', 'block'],
                            'activities' => ['Photography', 'Swimming', 'Hiking', 'Nature Walk', 'Picnicking', 'Relaxation'],
                        ],
                        'beach' => [
                            'keywords' => ['beach', 'lagoon', 'cove', 'sandbar', 'coastal'],
                            'activities' => ['Swimming', 'Sunbathing', 'Snorkeling', 'Surfing', 'Sightseeing', 'Picnicking', 'Relaxation', 'Photography'],
                        ],
                        'nature' => [
                            'keywords' => ['national park', 'sanctuary', 'reserve', 'wildlife', 'forest', 'wetland', 'jungle'],
                            'activities' => ['Bird Watching', 'Hiking', 'Nature Walk', 'Photography', 'Sightseeing', 'Kayaking'],
                        ],
                        'adventure' => [
                            'keywords' => ['adventure', 'tea estate', 'view point', 'hiking', 'trekking'],
                            'activities' => ['Hiking', 'Bird Watching', 'Kayaking', 'Snorkeling', 'Cycling', 'Nature Walk', 'Photography'],
                        ],
                        'heritage' => [
                            'keywords' => ['fort', 'palace', 'archaeological', 'architecture', 'heritage', 'historical', 'ancient'],
                            'activities' => ['Historical Tours', 'Cultural Tours', 'Photography', 'Sightseeing'],
                        ],
                    ];
                    $activityOpts = ['Photography', 'Swimming', 'Hiking', 'Bird Watching', 'Picnicking', 'Nature Walk', 'Prayer and Meditation', 'Sightseeing', 'Snorkeling', 'Surfing', 'Kayaking', 'Cultural Tours', 'Historical Tours', 'Relaxation', 'Sunbathing', 'Cycling', 'Reflection'];
                    // The form submits activities_selected[]/activities_other, never a
                    // bare "activities" key — so on a validation-error redisplay, old()
                    // must be read from those two actual field names, not a nonexistent
                    // "activities" key (which would silently fall back to the pre-edit
                    // DB value and discard the user's just-submitted checkbox changes).
                    if (old('activities_selected') !== null || old('activities_other') !== null) {
                        $selectedKnown = old('activities_selected', []);
                        $otherActivities = old('activities_other', '');
                    } else {
                        $currActivitiesRaw = $place->activities;
                        $currActivitiesList = $currActivitiesRaw ? array_map('trim', explode(',', $currActivitiesRaw)) : [];
                        $selectedKnown = array_intersect($currActivitiesList, $activityOpts);
                        $otherActivities = implode(', ', array_diff($currActivitiesList, $activityOpts));
                    }

                    // which groups each activity belongs to, e.g. "Photography" => "religious waterfall beach nature adventure heritage"
                    $activityToGroups = [];
                    foreach ($activityOpts as $opt) {
                        $groups = [];
                        foreach ($activityGroups as $groupName => $group) {
                            if (in_array($opt, $group['activities'])) $groups[] = $groupName;
                        }
                        $activityToGroups[$opt] = implode(' ', $groups);
                    }
                @endphp
                <div id="activities_grid" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2 mb-3">
                    @foreach($activityOpts as $opt)
                        <label class="activity-checkbox flex items-center gap-2 bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-xs text-slate-300 cursor-pointer hover:border-emerald-500/50" data-groups="{{ $activityToGroups[$opt] }}">
                            <input type="checkbox" name="activities_selected[]" value="{{ $opt }}" {{ in_array($opt, $selectedKnown) ? 'checked' : '' }} class="w-3.5 h-3.5 rounded text-emerald-600 focus:ring-emerald-500 shrink-0">
                            <span class="truncate">{{ $opt }}</span>
                        </label>
                    @endforeach
                </div>
                <input type="text" name="activities_other" value="{{ old('activities_other', $otherActivities) }}" placeholder="Other activities (comma-separated)"
                    class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Family Friendly</label>
                    <select name="family_friendly" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('family_friendly', $place->family_friendly) == 'yes' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('family_friendly', $place->family_friendly) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Budget Category</label>
                    @php
                        $budOpts = ['Free', 'Budget', 'Moderate', 'Expensive', 'Premium'];
                        $currBud = old('budget_category', $place->budget_category);
                    @endphp
                    <select name="budget_category" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Budget</option>
                        @foreach($budOpts as $opt)
                            <option value="{{ $opt }}" {{ $currBud == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currBud && !in_array($currBud, $budOpts))
                            <option value="{{ $currBud }}" selected>{{ $currBud }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Ticket Price</label>
                    <input type="text" name="ticket_price" value="{{ old('ticket_price', $place->ticket_price ?: $place->ticket_range) }}"
                        placeholder="e.g. Free, LKR 60 (local adult), USD 40 (foreign adult)"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                </div>
            </div>
        </div>

        <!-- Tab 4: Access, Amenities & Safety Advisories -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="access">
            <h3 class="text-sm font-semibold text-rose-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-shield-halved"></i> Access, Amenities & Safety Advisories
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Mobile Signal</label>
                    @php
                        $sigOpts = ['Excellent (4G/5G)', 'Good', 'Moderate', 'Poor', 'No Signal', 'Unknown'];
                        $currSig = old('mobile_signal', $place->mobile_signal);
                    @endphp
                    <select name="mobile_signal" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Signal</option>
                        @foreach($sigOpts as $opt)
                            <option value="{{ $opt }}" {{ $currSig == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currSig && !in_array($currSig, $sigOpts))
                            <option value="{{ $currSig }}" selected>{{ $currSig }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Road Condition</label>
                    @php
                        $roadOpts = ['Paved', 'Trekking', 'Forest Path', 'Rough / 4WD Recommended'];
                        $currRoad = old('road_condition', $place->road_condition ?: $place->road_type);
                    @endphp
                    <select name="road_condition" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Condition</option>
                        @foreach($roadOpts as $opt)
                            <option value="{{ $opt }}" {{ $currRoad == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currRoad && !in_array($currRoad, $roadOpts))
                            <option value="{{ $currRoad }}" selected>{{ $currRoad }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Parking Avail</label>
                    <select name="parking_avail" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('parking_avail', $place->parking_avail) == 'yes' || old('parking_range', $place->parking_range) == 'Available' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('parking_avail', $place->parking_avail) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Toilets Available</label>
                    <select name="toilets" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('toilets', $place->toilets) == 'yes' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('toilets', $place->toilets) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Food Nearby</label>
                    <select name="food_nearby" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('food_nearby', $place->food_nearby) == 'yes' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('food_nearby', $place->food_nearby) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Wheelchair Access</label>
                    <select name="wheelchair_access" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('wheelchair_access', $place->wheelchair_access) == 'yes' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('wheelchair_access', $place->wheelchair_access) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Camping Allowed</label>
                    <select name="camping_allowed" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('camping_allowed', $place->camping_allowed) == 'yes' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('camping_allowed', $place->camping_allowed) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Guide Required</label>
                    <select name="guide_required" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('guide_required', $place->guide_required) == 'yes' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('guide_required', $place->guide_required) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Safety Level</label>
                    @php
                        $safeOpts = ['Safe', 'Moderate', 'High'];
                        $currSafe = old('safety_level', $place->safety_level);
                    @endphp
                    <select name="safety_level" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Safety</option>
                        @foreach($safeOpts as $opt)
                            <option value="{{ $opt }}" {{ $currSafe == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currSafe && !in_array($currSafe, $safeOpts))
                            <option value="{{ $currSafe }}" selected>{{ $currSafe }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Wildlife Hazard</label>
                    <input type="text" name="wildlife_hazard" value="{{ old('wildlife_hazard', $place->wildlife_hazard) }}"
                        placeholder="e.g. None, Leeches during rainy days, Beware of hornets"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Rain Sensitivity</label>
                    @php
                        $rainOpts = ['Safe', 'Dangerous during heavy rain', 'Generally dry, but avoid May-Sept', 'Low'];
                        $currRain = old('rain_sensitivity', $place->rain_sensitivity);
                    @endphp
                    <select name="rain_sensitivity" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Rain Sensitivity</option>
                        @foreach($rainOpts as $opt)
                            <option value="{{ $opt }}" {{ $currRain == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currRain && !in_array($currRain, $rainOpts))
                            <option value="{{ $currRain }}" selected>{{ $currRain }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Monsoon Note</label>
                    <input type="text" name="monsoon_note" value="{{ old('monsoon_note', $place->monsoon_note) }}"
                        placeholder="e.g. Avoid May-Sept, roads may flood Nov-Dec"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Height (m)</label>
                    <input type="text" name="height_m" value="{{ old('height_m', $place->height_m) }}" placeholder="e.g. 0 or 1200"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Length (km)</label>
                    <input type="text" name="length_km" value="{{ old('length_km', $place->length_km) }}" placeholder="e.g. 0 or 3.5"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Surfing</label>
                    <select name="surfing" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="">Select</option>
                        <option value="yes" {{ old('surfing', $place->surfing) == 'yes' ? 'selected' : '' }}>Yes</option>
                        <option value="no" {{ old('surfing', $place->surfing) == 'no' ? 'selected' : '' }}>No</option>
                    </select>
                </div>
            </div>
        </div>

        <!-- Tab 5: AR & Audio Guides -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="ar">
            <h3 class="text-sm font-semibold text-purple-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-cube"></i> AR Model & Audio Guide Links
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 items-center">
                <div class="flex items-center gap-3 bg-slate-900 p-3 rounded-xl border border-slate-800">
                    <input type="checkbox" name="ar_supported" value="1" {{ old('ar_supported', $place->ar_supported) ? 'checked' : '' }} id="ar_supported" class="w-4 h-4 rounded text-purple-600 focus:ring-purple-500">
                    <label for="ar_supported" class="text-xs font-semibold text-white cursor-pointer">Enable AR Experience</label>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">AR Tier (1=Hero, 3=Basic)</label>
                    <select name="ar_tier" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                        <option value="1" {{ old('ar_tier', $place->ar_tier) == 1 ? 'selected' : '' }}>Tier 1 - Ultra High Res Hero</option>
                        <option value="2" {{ old('ar_tier', $place->ar_tier) == 2 ? 'selected' : '' }}>Tier 2 - Standard Model</option>
                        <option value="3" {{ old('ar_tier', $place->ar_tier) == 3 ? 'selected' : '' }}>Tier 3 - Basic Optimized</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Model Scale</label>
                    <input type="number" step="0.0001" name="ar_model_scale" value="{{ old('ar_model_scale', $place->ar_model_scale ?: 0.0100) }}"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">AR GLB Model URL</label>
                    <input type="url" name="ar_model_url" value="{{ old('ar_model_url', $place->ar_model_url) }}"
                        placeholder="https://cdn.hiddengemssl.com/models/sigiriya.glb"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Historical Reconstruction GLB URL</label>
                    <input type="url" name="ar_historical_model_url" value="{{ old('ar_historical_model_url', $place->ar_historical_model_url) }}"
                        placeholder="https://cdn.hiddengemssl.com/models/sigiriya_ancient.glb"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Audio Guide URL (Sinhala)</label>
                    <input type="url" name="audio_guide_url_si" value="{{ old('audio_guide_url_si', $place->audio_guide_url_si) }}"
                        placeholder="https://cdn.hiddengemssl.com/audio/sigiriya_si.mp3"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Audio Guide URL (English)</label>
                    <input type="url" name="audio_guide_url_en" value="{{ old('audio_guide_url_en', $place->audio_guide_url_en) }}"
                        placeholder="https://cdn.hiddengemssl.com/audio/sigiriya_en.mp3"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono">
                </div>
            </div>
        </div>

        <!-- Tab 6: Media Gallery & Uploads -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="media">
            <h3 class="text-sm font-semibold text-amber-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-images"></i> Dual-Tier WebP Image Management
            </h3>

            <div>
                <label class="block text-xs font-semibold text-slate-300 mb-2">Upload Photos (Auto-converted to 400px Thumb & 1080px Hero WebP)</label>
                <div class="flex items-center justify-center w-full">
                    <label id="images_dropzone_label" class="flex flex-col items-center justify-center w-full h-32 border-2 border-slate-700 border-dashed rounded-2xl cursor-pointer bg-slate-900/50 hover:bg-slate-900 transition">
                        <div id="images_dropzone_placeholder" class="flex flex-col items-center justify-center pt-5 pb-6">
                            <i class="fa-solid fa-cloud-arrow-up text-2xl text-emerald-400 mb-2"></i>
                            <p class="text-xs text-slate-400"><span class="font-semibold text-white">Click to upload</span> or drag and drop</p>
                            <p class="text-[10px] text-slate-500 mt-1">PNG, JPG, WEBP (Multiple allowed)</p>
                        </div>
                        <input type="file" id="images_input" name="images[]" multiple accept="image/*" class="hidden">
                    </label>
                </div>
                <!-- Client-side preview only — confirms the browser actually picked up
                     the files before the form is submitted. This is not yet uploaded
                     to the server; the real upload happens on form submit (BUG report:
                     admins had no way to tell a selection succeeded until after saving
                     and reopening the edit page to see the Existing Gallery section). -->
                <div id="images_preview_wrap" class="mt-3 hidden">
                    <p id="images_preview_count" class="text-[11px] font-semibold text-emerald-400 mb-2"></p>
                    <div id="images_preview_grid" class="grid grid-cols-2 md:grid-cols-4 gap-3"></div>
                </div>
            </div>

            @if($isEdit && $place->images->isNotEmpty())
                <div class="mt-4">
                    <label class="block text-xs font-semibold text-slate-400 mb-2">Existing Gallery Photos ({{ $place->images->count() }})</label>
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                        @foreach($place->images as $img)
                            <div class="relative group bg-slate-900 rounded-xl p-2 border {{ $img->is_cover ? 'border-emerald-500 shadow-lg shadow-emerald-950/50' : 'border-slate-800' }}">
                                <img src="{{ $img->thumb_path }}" class="w-full h-24 object-cover rounded-lg {{ $img->status === 'processing' ? 'opacity-50 animate-pulse' : '' }}">
                                @if($img->status === 'processing')
                                    <span class="absolute top-3 right-3 bg-amber-500 text-slate-950 text-[9px] font-bold px-1.5 py-0.5 rounded shadow flex items-center gap-1">
                                        <i class="fa-solid fa-spinner fa-spin"></i> Processing
                                    </span>
                                @elseif($img->status === 'failed')
                                    <span class="absolute top-3 right-3 bg-red-600 text-white text-[9px] font-bold px-1.5 py-0.5 rounded shadow" title="Image processing failed — try re-uploading.">
                                        <i class="fa-solid fa-triangle-exclamation"></i> Failed
                                    </span>
                                @endif
                                @if($img->is_cover)
                                    <span class="absolute top-3 left-3 bg-emerald-500 text-white text-[9px] font-bold px-1.5 py-0.5 rounded shadow">COVER</span>
                                @endif

                                @if(auth()->user()->isFullAdmin())
                                <div class="absolute inset-0 bg-slate-950/80 rounded-xl opacity-0 group-hover:opacity-100 flex items-center justify-center gap-2 transition duration-200">
                                    @if(!$img->is_cover)
                                        <button type="submit" form="cover-form-{{ $img->id }}" class="p-2 rounded-lg bg-emerald-600 text-white hover:bg-emerald-500 text-xs shadow" title="Set Cover">
                                            <i class="fa-solid fa-star"></i>
                                        </button>
                                    @endif
                                    <button type="submit" form="delete-form-{{ $img->id }}" class="p-2 rounded-lg bg-red-600 text-white hover:bg-red-500 text-xs shadow" title="Delete" onclick="return confirm('Delete photo?')">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </div>
                                @endif
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif
        </div>

        <div class="flex items-center justify-end gap-4 pt-4">
            <a href="{{ route('admin.places.index') }}" class="px-5 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-sm font-semibold transition">
                Cancel
            </a>
            <button type="submit" class="px-6 py-2.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-sm font-bold shadow-lg shadow-emerald-900/50 transition glow-effect">
                <i class="fa-solid fa-check mr-1"></i> {{ $isEdit ? 'Save Changes & Increment Version' : 'Create Gem Record' }}
            </button>
        </div>
    </form>

    <!-- Hidden forms for image actions -->
    @if($isEdit)
        @foreach($place->images as $img)
            <form id="cover-form-{{ $img->id }}" action="{{ route('admin.images.cover', $img->id) }}" method="POST" class="hidden">
                @csrf
            </form>
            <form id="delete-form-{{ $img->id }}" action="{{ route('admin.images.delete', $img->id) }}" method="POST" class="hidden">
                @csrf
                @method('DELETE')
            </form>
        @endforeach
    @endif
</div>

@if(!$isEdit)
<script>
document.addEventListener('DOMContentLoaded', function() {
    const distInput = document.getElementById('district_input');
    const catInput = document.getElementById('category_input');
    const idInput = document.getElementById('gem_id_input');

    const catMap = {
        'waterfalls': 'WF',
        'beach': 'BE',
        'religious places': 'TM',
        'temple': 'TM',
        'sacred temple': 'TM',
        'view point': 'VP',
        'tea estate': 'TE',
        'adventure park': 'AP',
        'ancient architecture': 'ARC',
        'colonial fort': 'CF',
        'royal palace': 'RP',
        'historical monument': 'HM',
        'wildlife / national park': 'WL',
        'hiking / trekking': 'HK',
        'village experience': 'VE',
        'culinary / food': 'FD',
        'cultural site': 'CS'
    };

    // Explicit map, not a first-3-letters rule: Matale and Matara both
    // truncate to "MAT" and would silently collide onto the same ID prefix.
    // Mirrors PlaceController::generateSmartId()'s $districtCodeMap — keep
    // both in sync if a district is ever added/renamed.
    const distMap = {
        'ampara': 'AMP', 'anuradhapura': 'ANU', 'badulla': 'BAD',
        'batticaloa': 'BAT', 'colombo': 'COL', 'galle': 'GAL',
        'gampaha': 'GAM', 'hambantota': 'HAM', 'jaffna': 'JAF',
        'kalutara': 'KAL', 'kandy': 'KAN', 'kegalle': 'KEG',
        'kilinochchi': 'KIL', 'kurunegala': 'KUR', 'mannar': 'MAN',
        'matale': 'MTL', 'matara': 'MTR', 'moneragala': 'MON',
        'mullaitivu': 'MUL', 'nuwara eliya': 'NUW', 'polonnaruwa': 'POL',
        'puttalam': 'PUT', 'ratnapura': 'RAT', 'trincomalee': 'TRI',
        'vavuniya': 'VAV'
    };

    function updateSmartId() {
        if (idInput && distInput && catInput && !idInput.dataset.manual) {
            const distKey = distInput.value.trim().toLowerCase();
            const distVal = distMap[distKey] || (distInput.value.trim().replace(/[^a-zA-Z]/g, '').substring(0, 3).toUpperCase() || 'SL');
            const catVal = catInput.value.trim().toLowerCase();
            const catCode = catMap[catVal] || (catInput.value.trim().replace(/[^a-zA-Z]/g, '').substring(0, 3).toUpperCase() || 'GEM');

            if (distInput.value.trim() || catInput.value.trim()) {
                idInput.value = `${catCode}-${distVal}-001`;
            }
        }
    }

    if (distInput) distInput.addEventListener('input', updateSmartId);
    if (catInput) catInput.addEventListener('change', updateSmartId);
    if (idInput) {
        idInput.addEventListener('input', function() {
            idInput.dataset.manual = "true";
        });
    }
});
</script>
@endif

<script>
document.addEventListener('DOMContentLoaded', function() {
    const distInput = document.getElementById('district_input');
    const provInput = document.getElementById('province_input');
    const provDisplay = document.getElementById('province_display');

    const districtToProvince = {
        'Colombo': 'Western', 'Gampaha': 'Western', 'Kalutara': 'Western',
        'Kandy': 'Central', 'Matale': 'Central', 'Nuwara Eliya': 'Central',
        'Galle': 'Southern', 'Matara': 'Southern', 'Hambantota': 'Southern',
        'Jaffna': 'Northern', 'Kilinochchi': 'Northern', 'Mannar': 'Northern', 'Mullaitivu': 'Northern', 'Vavuniya': 'Northern',
        'Batticaloa': 'Eastern', 'Ampara': 'Eastern', 'Trincomalee': 'Eastern',
        'Kurunegala': 'North Western', 'Puttalam': 'North Western',
        'Anuradhapura': 'North Central', 'Polonnaruwa': 'North Central',
        'Badulla': 'Uva', 'Moneragala': 'Uva',
        'Ratnapura': 'Sabaragamuwa', 'Kegalle': 'Sabaragamuwa',
    };

    function updateProvince() {
        if (distInput && provInput) {
            const province = districtToProvince[distInput.value] || '';
            provInput.value = province;
            if (provDisplay) provDisplay.textContent = province || '—';
        }
    }

    if (distInput) {
        distInput.addEventListener('change', updateProvince);
        updateProvince(); // sync on load (edit mode: district pre-selected)
    }
});
</script>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const linkInput = document.getElementById('maps_link_input');
    const parseBtn = document.getElementById('maps_link_parse_btn');
    const statusEl = document.getElementById('maps_link_status');
    const latInput = document.getElementById('lat_input');
    const lngInput = document.getElementById('lng_input');
    if (!parseBtn || !latInput || !lngInput) return;

    // Google Maps share links vary a lot depending on where they were
    // copied from — cover the common shapes rather than assume one format.
    function extractLatLng(url) {
        const patterns = [
            /@(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)/,       // .../@7.957,80.7603,15z
            /[?&]q=(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)/,   // ?q=7.957,80.7603
            /!3d(-?\d{1,3}\.\d+)!4d(-?\d{1,3}\.\d+)/,    // .../!3d7.957!4d80.7603 (place-detail links)
            /^\s*(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)\s*$/, // bare "lat, lng" pasted directly
        ];
        for (const re of patterns) {
            const m = url.match(re);
            if (m) return { lat: parseFloat(m[1]), lng: parseFloat(m[2]) };
        }
        return null;
    }

    function showStatus(message, isError) {
        statusEl.textContent = message;
        statusEl.className = 'text-[11px] mt-1.5 ' + (isError ? 'text-red-400' : 'text-emerald-400');
    }

    function applyCoords(coords) {
        latInput.value = coords.lat;
        lngInput.value = coords.lng;
        showStatus('Coordinates filled: ' + coords.lat + ', ' + coords.lng, false);
    }

    function isShortLink(url) {
        // Shortened Google Maps links (maps.app.goo.gl, goo.gl) never contain
        // the coordinates themselves — those only appear in the full URL
        // Google redirects to, which the browser can't follow cross-origin
        // from client-side JS. resolve-maps-link fetches it server-side.
        return /^https?:\/\/(maps\.app\.goo\.gl|goo\.gl)\//i.test(url.trim());
    }

    parseBtn.addEventListener('click', function() {
        const url = (linkInput.value || '').trim();
        if (!url) {
            showStatus('Paste a Google Maps link first.', true);
            return;
        }

        const coords = extractLatLng(url);
        if (coords && coords.lat >= -90 && coords.lat <= 90 && coords.lng >= -180 && coords.lng <= 180) {
            applyCoords(coords);
            return;
        }

        if (!isShortLink(url)) {
            showStatus('Could not find coordinates in that link — try the "Share" → "Copy link" option from Google Maps, or type Latitude/Longitude manually below.', true);
            return;
        }

        // Short link with no inline coordinates — resolve it server-side first.
        showStatus('Resolving shortened link…', false);
        parseBtn.disabled = true;

        fetch('{{ route("admin.places.resolve-maps-link") }}?url=' + encodeURIComponent(url), {
            headers: { 'Accept': 'application/json' }
        })
            .then(function(res) { return res.json().then(function(body) { return { ok: res.ok, body: body }; }); })
            .then(function(result) {
                parseBtn.disabled = false;
                if (!result.ok || !result.body.resolved_url) {
                    showStatus(result.body.error || 'Could not resolve that link.', true);
                    return;
                }
                const resolvedCoords = extractLatLng(result.body.resolved_url);
                if (!resolvedCoords) {
                    showStatus('Resolved the link, but could not find coordinates in it. Try typing Latitude/Longitude manually below.', true);
                    return;
                }
                applyCoords(resolvedCoords);
            })
            .catch(function() {
                parseBtn.disabled = false;
                showStatus('Could not resolve that link — check your connection and try again.', true);
            });
    });
});
</script>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const catInput = document.getElementById('category_input');
    const checkboxLabels = document.querySelectorAll('#activities_grid .activity-checkbox');

    // Keyword groups mirrored from the PHP $activityGroups map above —
    // matched as case-insensitive substrings against the category text so
    // messy variants ("Temple/Stupa", "Sandy Beach (Kitesurf)") still hit.
    const categoryKeywordGroups = {
        religious: ['temple', 'kovil', 'mosque', 'church', 'shrine', 'devale', 'devalaya', 'stupa', 'monastery', 'sanctuary', 'basilica', 'chapel', 'cathedral'],
        waterfall: ['cascade', 'plunge', 'waterfall', 'fall', 'horsetail', 'tiered', 'segmented', 'fan', 'block'],
        beach: ['beach', 'lagoon', 'cove', 'sandbar', 'coastal'],
        nature: ['national park', 'sanctuary', 'reserve', 'wildlife', 'forest', 'wetland', 'jungle'],
        adventure: ['adventure', 'tea estate', 'view point', 'hiking', 'trekking'],
        heritage: ['fort', 'palace', 'archaeological', 'architecture', 'heritage', 'historical', 'ancient'],
    };

    function matchingGroups(categoryText) {
        const lower = categoryText.toLowerCase();
        return Object.keys(categoryKeywordGroups).filter(function(group) {
            return categoryKeywordGroups[group].some(function(kw) { return lower.includes(kw); });
        });
    }

    function filterActivities() {
        if (!catInput) return;
        const groups = matchingGroups(catInput.value || '');

        checkboxLabels.forEach(function(label) {
            const checkbox = label.querySelector('input[type="checkbox"]');
            const labelGroups = (label.dataset.groups || '').split(' ').filter(Boolean);
            const isRelevant = groups.length === 0 || labelGroups.some(function(g) { return groups.includes(g); });
            // Always keep a checkbox visible if it's already checked (existing
            // data shouldn't silently disappear just because the category
            // filter would otherwise hide it), or if no category is selected
            // yet / no keyword group matched (show everything as a fallback).
            label.style.display = (isRelevant || checkbox.checked) ? '' : 'none';
        });
    }

    if (catInput) {
        catInput.addEventListener('change', filterActivities);
        filterActivities(); // sync on load (edit mode: category pre-selected)
    }
});
</script>

<style>
    .form-tab-btn { color: #94a3b8; }
    .form-tab-btn:hover { color: #e2e8f0; background: rgba(148, 163, 184, 0.08); }
    .form-tab-btn.active { color: white; background: linear-gradient(to right, rgb(5 150 105), rgb(13 148 136)); box-shadow: 0 2px 10px -2px rgba(16, 185, 129, 0.4); }
    .form-tab-panel { display: none; }
    .form-tab-panel.active { display: block; }
</style>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const tabButtons = document.querySelectorAll('.form-tab-btn');
    const panels = document.querySelectorAll('.form-tab-panel');

    function showTab(name) {
        tabButtons.forEach(function(btn) {
            btn.classList.toggle('active', btn.dataset.tab === name);
        });
        panels.forEach(function(panel) {
            panel.classList.toggle('active', panel.dataset.panel === name);
        });
    }

    tabButtons.forEach(function(btn) {
        btn.addEventListener('click', function() { showTab(btn.dataset.tab); });
    });

    // On a validation-error redisplay, jump straight to whichever tab holds
    // the first invalid field — errors can land on any of the 6 tabs, and
    // silently defaulting to "Core Info" would hide the actual problem from
    // the user (e.g. a bad lat/lng error on the GPS tab going unnoticed).
    let initialTab = 'core';
    const firstInvalidName = @json($errors->any() ? array_key_first($errors->toArray()) : null);
    if (firstInvalidName) {
        const fieldToTab = {
            id: 'core', name: 'core', district: 'core', category: 'core',
            lat: 'gps', lng: 'gps', geohash: 'gps',
            description: 'insights', province: 'insights', opening_hours: 'insights',
            best_time_to_visit: 'insights', tourist_popularity: 'insights',
            activities_selected: 'insights', activities_other: 'insights',
            family_friendly: 'insights', budget_category: 'insights', ticket_price: 'insights',
            mobile_signal: 'access', road_condition: 'access', parking_avail: 'access',
            toilets: 'access', food_nearby: 'access', wheelchair_access: 'access',
            camping_allowed: 'access', guide_required: 'access', safety_level: 'access',
            wildlife_hazard: 'access', rain_sensitivity: 'access', monsoon_note: 'access',
            height_m: 'access', length_km: 'access', surfing: 'access',
            ar_supported: 'ar', ar_tier: 'ar', ar_model_scale: 'ar', ar_model_url: 'ar',
            ar_historical_model_url: 'ar', audio_guide_url_si: 'ar', audio_guide_url_en: 'ar',
            'images.0': 'media', 'images': 'media',
        };
        initialTab = fieldToTab[firstInvalidName] || 'core';
    }

    showTab(initialTab);

    // A required field left empty on a tab other than the currently-visible
    // one fails HTML5 validation silently — the browser can't focus/show its
    // bubble on a hidden (display:none) element, so the click just does
    // nothing with zero visible feedback. Jump to that field's tab first so
    // the browser's native validation bubble actually has something visible
    // to attach to.
    const placeForm = document.getElementById('place_form');
    if (placeForm) {
        placeForm.addEventListener('submit', function(e) {
            const firstInvalid = placeForm.querySelector(':invalid');
            if (firstInvalid) {
                const panel = firstInvalid.closest('.form-tab-panel');
                if (panel && !panel.classList.contains('active')) {
                    e.preventDefault();
                    showTab(panel.dataset.panel);
                    setTimeout(function() {
                        firstInvalid.reportValidity();
                    }, 50);
                }
            }
        });
    }

    // Client-side preview of picked-but-not-yet-uploaded files, so an admin
    // can confirm the browser actually registered the selection before
    // submitting — previously the only feedback was the native OS file-picker
    // dialog closing, with no on-page confirmation until saving and
    // reopening the edit page to see "Existing Gallery Photos".
    const imagesInput = document.getElementById('images_input');
    const previewWrap = document.getElementById('images_preview_wrap');
    const previewCount = document.getElementById('images_preview_count');
    const previewGrid = document.getElementById('images_preview_grid');

    if (imagesInput) {
        imagesInput.addEventListener('change', function() {
            previewGrid.innerHTML = '';
            const files = Array.from(imagesInput.files || []);

            if (files.length === 0) {
                previewWrap.classList.add('hidden');
                return;
            }

            previewCount.textContent = files.length + ' file' + (files.length === 1 ? '' : 's') + ' selected — not saved yet, click "' + (@json($isEdit) ? 'Save Changes' : 'Create Gem Record') + '" below to upload.';
            files.forEach(function(file) {
                const url = URL.createObjectURL(file);
                const cell = document.createElement('div');
                cell.className = 'relative bg-slate-900 rounded-xl p-2 border border-slate-800';
                const img = document.createElement('img');
                img.src = url;
                img.className = 'w-full h-24 object-cover rounded-lg';
                img.onload = function() { URL.revokeObjectURL(url); };
                cell.appendChild(img);
                previewGrid.appendChild(cell);
            });
            previewWrap.classList.remove('hidden');
        });
    }
});
</script>
@endsection
