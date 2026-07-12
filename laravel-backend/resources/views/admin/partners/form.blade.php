@extends('admin.layout')

@php
    $isEdit = $partner !== null;
    $val = fn($key, $default = null) => old($key, $isEdit ? ($partner[$key] ?? $default) : $default);
@endphp

@section('content')
<div class="max-w-3xl mx-auto space-y-6">
    <!-- Header/Breadcrumb -->
    <div>
        <a href="{{ route('admin.partners.index') }}" class="text-sm font-semibold text-emerald-400 hover:text-emerald-300 transition flex items-center gap-1.5 mb-2">
            <i class="fa-solid fa-arrow-left"></i> Back to Partners
        </a>
        <h2 class="text-2xl font-bold tracking-tight text-white">
            {{ $isEdit ? "Edit Partner" : "Add Curator Partner" }}
        </h2>
        <p class="text-sm text-slate-400">
            {{ $isEdit ? "Update this partner's details or deal." : "Register a boutique stay, cafe, or guide as a nearby partner." }}
        </p>
    </div>

    <!-- Form Container -->
    <div class="glass-card p-6 md:p-8 rounded-3xl">
        <form action="{{ $isEdit ? route('admin.partners.update', $partner['id']) : route('admin.partners.store') }}" method="POST" class="space-y-6">
            @csrf
            @if($isEdit)
                @method('PUT')
            @endif

            <!-- Name -->
            <div class="space-y-2">
                <label for="name" class="block text-sm font-semibold text-slate-300">Partner Name <span class="text-red-500">*</span></label>
                <input type="text" name="name" id="name" value="{{ $val('name') }}" required placeholder="e.g., Ceylon Tea Trails Boutique" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
            </div>

            <!-- Description -->
            <div class="space-y-2">
                <label for="description" class="block text-sm font-semibold text-slate-300">Description</label>
                <textarea name="description" id="description" rows="3" placeholder="Short description shown in the app..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">{{ $val('description') }}</textarea>
            </div>

            <!-- Category / Price Range / Rating -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="space-y-2">
                    <label for="category" class="block text-sm font-semibold text-slate-300">Category <span class="text-red-500">*</span></label>
                    <select name="category" id="category" required class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                        @foreach(['hotel' => 'Hotel / Stay', 'cafe' => 'Cafe / Restaurant', 'guide' => 'Guide', 'artisan' => 'Artisan / Craft'] as $key => $label)
                            <option value="{{ $key }}" {{ $val('category') == $key ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="space-y-2">
                    <label for="priceRange" class="block text-sm font-semibold text-slate-300">Price Range</label>
                    <input type="text" name="priceRange" id="priceRange" value="{{ $val('priceRange', '$$') }}" placeholder="$, $$, $$$" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                </div>
                <div class="space-y-2">
                    <label for="rating" class="block text-sm font-semibold text-slate-300">Rating (0–5)</label>
                    <input type="number" step="0.1" min="0" max="5" name="rating" id="rating" value="{{ $val('rating', 4.0) }}" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                </div>
            </div>

            <!-- Location -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label for="lat" class="block text-sm font-semibold text-slate-300">Latitude <span class="text-red-500">*</span></label>
                    <input type="number" step="any" name="lat" id="lat" value="{{ $val('lat') }}" required class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white font-mono focus:outline-none focus:border-emerald-500/50 transition">
                </div>
                <div class="space-y-2">
                    <label for="lng" class="block text-sm font-semibold text-slate-300">Longitude <span class="text-red-500">*</span></label>
                    <input type="number" step="any" name="lng" id="lng" value="{{ $val('lng') }}" required class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white font-mono focus:outline-none focus:border-emerald-500/50 transition">
                </div>
            </div>

            <!-- Links -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label for="imageUrl" class="block text-sm font-semibold text-slate-300">Image URL</label>
                    <input type="text" name="imageUrl" id="imageUrl" value="{{ $val('imageUrl') }}" placeholder="https://..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                </div>
                <div class="space-y-2">
                    <label for="bookingUrl" class="block text-sm font-semibold text-slate-300">Booking / Contact URL</label>
                    <input type="text" name="bookingUrl" id="bookingUrl" value="{{ $val('bookingUrl') }}" placeholder="https:// or https://wa.me/..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                </div>
            </div>

            <!-- Verified toggle -->
            <div class="border-t border-slate-800/60 pt-6 flex items-center justify-between">
                <div>
                    <label for="isVerified" class="block text-sm font-semibold text-slate-300">Verified Partner</label>
                    <p class="text-xs text-slate-500">Shows a verified badge in the app.</p>
                </div>
                <div class="flex items-center">
                    <input type="hidden" name="isVerified" value="0">
                    <input type="checkbox" name="isVerified" id="isVerified" value="1" {{ $val('isVerified') ? 'checked' : '' }} class="w-5 h-5 rounded border-slate-800 text-emerald-500 focus:ring-emerald-500 bg-slate-900">
                </div>
            </div>

            <!-- Curator Deal -->
            <div class="border-t border-slate-800/60 pt-6 space-y-4">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-bold uppercase tracking-wider text-amber-400">Curator Deal (Premium Benefit)</h3>
                        <p class="text-xs text-slate-500 mt-1">When enabled, this partner appears in the app's premium-only Curator Deals screen.</p>
                    </div>
                    <div class="flex items-center">
                        <input type="hidden" name="isPremiumDeal" value="0">
                        <input type="checkbox" name="isPremiumDeal" id="isPremiumDeal" value="1" {{ $val('isPremiumDeal') ? 'checked' : '' }} class="w-5 h-5 rounded border-slate-800 text-amber-500 focus:ring-amber-500 bg-slate-900">
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label for="discountPercent" class="block text-sm font-semibold text-slate-300">Discount %</label>
                        <input type="number" min="0" max="100" name="discountPercent" id="discountPercent" value="{{ $val('discountPercent', 0) }}" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-amber-500/50 transition">
                    </div>
                    <div class="space-y-2">
                        <label for="dealValidUntil" class="block text-sm font-semibold text-slate-300">Valid Until</label>
                        <input type="date" name="dealValidUntil" id="dealValidUntil" value="{{ $val('dealValidUntil') ? \Illuminate\Support\Carbon::parse($val('dealValidUntil'))->format('Y-m-d') : '' }}" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-amber-500/50 transition">
                    </div>
                </div>
                <div class="space-y-2">
                    <label for="dealDescription" class="block text-sm font-semibold text-slate-300">Deal Description</label>
                    <input type="text" name="dealDescription" id="dealDescription" value="{{ $val('dealDescription') }}" placeholder="e.g., 20% off room rate + free breakfast for premium members" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-amber-500/50 transition">
                </div>
            </div>

            <!-- Submit buttons -->
            <div class="border-t border-slate-800/60 pt-6 flex items-center justify-end gap-3">
                <a href="{{ route('admin.partners.index') }}" class="text-sm font-semibold text-slate-400 hover:text-slate-200 transition py-2 px-4">
                    Cancel
                </a>
                <button type="submit" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold shadow-md shadow-emerald-950/20 transition duration-200 glow-effect">
                    {{ $isEdit ? "Save Changes" : "Add Partner" }}
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
