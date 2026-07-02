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

    <form action="{{ $action }}" method="POST" enctype="multipart/form-data" class="space-y-6">
        @csrf
        @if($isEdit)
            @method('PUT')
        @endif

        <!-- Card 1: Core Identification -->
        <div class="glass-card p-6 rounded-2xl space-y-4 border border-slate-800">
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

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
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
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Category *</label>
                    @php
                        $defaultCats = ['Adventure Park', 'Religious Places', 'Temple', 'Beach', 'Tea Estate', 'View Point', 'Waterfalls', 'Ancient Architecture', 'Colonial Fort', 'Royal Palace', 'Sacred Temple', 'Natural Heritage', 'Historical Monument', 'Wildlife / National Park', 'Hiking / Trekking', 'Village Experience', 'Culinary / Food', 'Cultural Site', 'General'];
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
                <div>
                    <label class="block text-xs font-semibold text-amber-400 mb-1 flex items-center gap-1"><i class="fa-solid fa-crown text-amber-400"></i> Access Tier</label>
                    <select name="access_tier" class="w-full px-3 py-2 bg-slate-900 border border-amber-500/50 rounded-xl text-xs text-amber-300 font-bold focus:outline-none focus:border-amber-400">
                        <option value="Free" {{ old('access_tier', $place->access_tier) == 'Free' ? 'selected' : '' }}>🟢 Free (Public)</option>
                        <option value="PRO" {{ old('access_tier', $place->access_tier) == 'PRO' ? 'selected' : '' }}>⭐ PRO (Subscribers Only)</option>
                        <option value="VIP" {{ old('access_tier', $place->access_tier) == 'VIP' ? 'selected' : '' }}>👑 VIP Exclusive</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Initial Rating (0-5)</label>
                    <input type="number" step="0.1" min="0" max="5" name="rating" value="{{ old('rating', $place->rating ?: 4.8) }}"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                </div>
            </div>
        </div>

        <!-- Card 2: Location Coordinates & GPS -->
        <div class="glass-card p-6 rounded-2xl space-y-4 border border-slate-800">
            <h3 class="text-sm font-semibold text-teal-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-earth-asia"></i> GPS Coordinates & Geohash
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Latitude (Decimal) *</label>
                    <input type="number" step="0.0000001" name="lat" value="{{ old('lat', $place->lat) }}" required
                        placeholder="e.g. 7.9570000"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Longitude (Decimal) *</label>
                    <input type="number" step="0.0000001" name="lng" value="{{ old('lng', $place->lng) }}" required
                        placeholder="e.g. 80.7603000"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Geohash</label>
                    <input type="text" name="geohash" value="{{ old('geohash', $place->geohash) }}"
                        placeholder="e.g. tc1y69"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500">
                </div>
            </div>
        </div>

        <!-- Card 3: Curated Travel Insights & Details -->
        <div class="glass-card p-6 rounded-2xl space-y-4 border border-slate-800">
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

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Province</label>
                    @php
                        $provOpts = ['Western', 'Central', 'Southern', 'Northern', 'Eastern', 'North Western', 'North Central', 'Uva', 'Sabaragamuwa'];
                        $currProv = old('province', $place->province);
                    @endphp
                    <select name="province" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Province</option>
                        @foreach($provOpts as $opt)
                            <option value="{{ $opt }}" {{ $currProv == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currProv && !in_array($currProv, $provOpts))
                            <option value="{{ $currProv }}" selected>{{ $currProv }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Opening Hours</label>
                    @php
                        $openOpts = ['Open daily 24/7', '6:00 AM - 6:00 PM (Daytime)', '8:00 AM - 5:00 PM (Standard)', '7:00 AM - 7:00 PM', 'Varies by season'];
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
                    @php
                        $bestOpts = ['All year round', 'Dec to Mar (Dry Season)', 'May to Sept (East Coast Best)', 'Early Morning / Sunrise', 'Late Afternoon / Sunset'];
                        $currBest = old('best_time_to_visit', $place->best_time_to_visit ?: $place->best_time);
                    @endphp
                    <select name="best_time_to_visit" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Best Time</option>
                        @foreach($bestOpts as $opt)
                            <option value="{{ $opt }}" {{ $currBest == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currBest && !in_array($currBest, $bestOpts))
                            <option value="{{ $currBest }}" selected>{{ $currBest }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Tourist Popularity</label>
                    @php
                        $popOpts = ['High / Famous', 'Medium / Moderate Crowd', 'Low / Remote & Secluded', 'Very High (Hotspot)'];
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

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Activities</label>
                    <input type="text" name="activities" value="{{ old('activities', $place->activities) }}" placeholder="e.g. Prayer, Photography, Hiking"
                        class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white">
                </div>
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
                        $budOpts = ['Free / No Entry Fee', 'Budget / Low Cost', 'Moderate', 'Luxury / Premium Experience'];
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
                    @php
                        $tktOpts = ['Free (Locals & Foreigners)', 'Free for Locals / Small Fee for Foreigners', 'LKR 100 - 500', 'LKR 500 - 1500', 'LKR 1500+ / Standard Heritage Ticket'];
                        $currTkt = old('ticket_price', $place->ticket_price ?: $place->ticket_range);
                    @endphp
                    <select name="ticket_price" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Ticket Price</option>
                        @foreach($tktOpts as $opt)
                            <option value="{{ $opt }}" {{ $currTkt == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currTkt && !in_array($currTkt, $tktOpts))
                            <option value="{{ $currTkt }}" selected>{{ $currTkt }} (Custom)</option>
                        @endif
                    </select>
                </div>
            </div>
        </div>

        <!-- Card 4: Access, Amenities & Safety Advisories -->
        <div class="glass-card p-6 rounded-2xl space-y-4 border border-slate-800">
            <h3 class="text-sm font-semibold text-rose-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-shield-halved"></i> Access, Amenities & Safety Advisories
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Mobile Signal</label>
                    @php
                        $sigOpts = ['Good', 'Moderate / Weak', 'None / Offline', 'Excellent / 4G/5G'];
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
                        $roadOpts = ['Paved / Tar Road', 'Offroad / Dirt Track', '4WD Only / Rough', 'Narrow / Winding', 'Walkway / Footpath Only'];
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
                        $safeOpts = ['Safe / High Security', 'Caution / Be Vigilant', 'Moderate / Slippery', 'High Risk / Dangerous', 'Guide Recommended'];
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
                    @php
                        $wildOpts = ['None', 'Elephants / Wild Boar', 'Leeches / Ticks', 'Monkeys / Baboons', 'Snake / Reptile Hazard', 'Stinging Insects / Wasps'];
                        $currWild = old('wildlife_hazard', $place->wildlife_hazard);
                    @endphp
                    <select name="wildlife_hazard" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Hazard</option>
                        @foreach($wildOpts as $opt)
                            <option value="{{ $opt }}" {{ $currWild == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currWild && !in_array($currWild, $wildOpts))
                            <option value="{{ $currWild }}" selected>{{ $currWild }} (Custom)</option>
                        @endif
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1">Rain Sensitivity</label>
                    @php
                        $rainOpts = ['Safe / All Weather', 'Slippery / Muddy in Rain', 'High Risk / Flash Floods', 'Impassable in Heavy Rain', 'Indoor Site'];
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
                    @php
                        $monsOpts = ['All Year Safe / No Monsoon Impact', 'Avoid South-West Monsoon (May-Sept)', 'Avoid North-East Monsoon (Oct-Jan)', 'Caution During Heavy Rains'];
                        $currMons = old('monsoon_note', $place->monsoon_note);
                    @endphp
                    <select name="monsoon_note" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Monsoon Note</option>
                        @foreach($monsOpts as $opt)
                            <option value="{{ $opt }}" {{ $currMons == $opt ? 'selected' : '' }}>{{ $opt }}</option>
                        @endforeach
                        @if($currMons && !in_array($currMons, $monsOpts))
                            <option value="{{ $currMons }}" selected>{{ $currMons }} (Custom)</option>
                        @endif
                    </select>
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

        <!-- Card 5: AR & Audio Guides -->
        <div class="glass-card p-6 rounded-2xl space-y-4 border border-slate-800">
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

        <!-- Card 4: Media Gallery & Uploads -->
        <div class="glass-card p-6 rounded-2xl space-y-4 border border-slate-800">
            <h3 class="text-sm font-semibold text-amber-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-images"></i> Dual-Tier WebP Image Management
            </h3>

            <div>
                <label class="block text-xs font-semibold text-slate-300 mb-2">Upload Photos (Auto-converted to 400px Thumb & 1080px Hero WebP)</label>
                <div class="flex items-center justify-center w-full">
                    <label class="flex flex-col items-center justify-center w-full h-32 border-2 border-slate-700 border-dashed rounded-2xl cursor-pointer bg-slate-900/50 hover:bg-slate-900 transition">
                        <div class="flex flex-col items-center justify-center pt-5 pb-6">
                            <i class="fa-solid fa-cloud-arrow-up text-2xl text-emerald-400 mb-2"></i>
                            <p class="text-xs text-slate-400"><span class="font-semibold text-white">Click to upload</span> or drag and drop</p>
                            <p class="text-[10px] text-slate-500 mt-1">PNG, JPG, WEBP (Multiple allowed)</p>
                        </div>
                        <input type="file" name="images[]" multiple accept="image/*" class="hidden">
                    </label>
                </div>
            </div>

            @if($isEdit && $place->images->isNotEmpty())
                <div class="mt-4">
                    <label class="block text-xs font-semibold text-slate-400 mb-2">Existing Gallery Photos ({{ $place->images->count() }})</label>
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                        @foreach($place->images as $img)
                            <div class="relative group bg-slate-900 rounded-xl p-2 border {{ $img->is_cover ? 'border-emerald-500 shadow-lg shadow-emerald-950/50' : 'border-slate-800' }}">
                                <img src="{{ $img->thumb_path }}" class="w-full h-24 object-cover rounded-lg">
                                @if($img->is_cover)
                                    <span class="absolute top-3 left-3 bg-emerald-500 text-white text-[9px] font-bold px-1.5 py-0.5 rounded shadow">COVER</span>
                                @endif

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

    function updateSmartId() {
        if (idInput && distInput && catInput && !idInput.dataset.manual) {
            const distVal = distInput.value.trim().replace(/[^a-zA-Z]/g, '').substring(0, 3).toUpperCase() || 'SL';
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
@endsection
