@extends('admin.layout')

@section('content')
<div class="max-w-3xl mx-auto space-y-6">
    <!-- Header/Breadcrumb -->
    <div>
        <a href="{{ route('admin.events.index') }}" class="text-sm font-semibold text-emerald-400 hover:text-emerald-300 transition flex items-center gap-1.5 mb-2">
            <i class="fa-solid fa-arrow-left"></i> Back to Events
        </a>
        <h2 class="text-2xl font-bold tracking-tight text-white">
            {{ $event->exists ? "Edit Event Details" : "Create New Calendar Event" }}
        </h2>
        <p class="text-sm text-slate-400">
            {{ $event->exists ? "Make adjustments to the event configurations." : "Configure a new cultural, seasonal, or religious event." }}
        </p>
    </div>

    <!-- Form Container -->
    <div class="glass-card p-6 md:p-8 rounded-3xl">
        <form action="{{ $event->exists ? route('admin.events.update', $event->id) : route('admin.events.store') }}" method="POST" class="space-y-6">
            @csrf
            @if($event->exists)
                @method('PUT')
            @endif

            <!-- Name -->
            <div class="space-y-2">
                <label for="name" class="block text-sm font-semibold text-slate-300">Event Name <span class="text-red-500">*</span></label>
                <input type="text" name="name" id="name" value="{{ old('name', $event->name) }}" required placeholder="e.g., Sinhala & Tamil New Year" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
            </div>

            <!-- Description -->
            <div class="space-y-2">
                <label for="description" class="block text-sm font-semibold text-slate-300">Description</label>
                <textarea name="description" id="description" rows="4" placeholder="Briefly describe the cultural significance, activities, or history of this event..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">{{ old('description', $event->description) }}</textarea>
            </div>

            <!-- Grid Layout for Category and Location -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Category -->
                <div class="space-y-2">
                    <label for="category" class="block text-sm font-semibold text-slate-300">Category <span class="text-red-500">*</span></label>
                    <select name="category" id="category" required class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                        <option value="">Select Category</option>
                        <option value="cultural" {{ old('category', $event->category) == 'cultural' ? 'selected' : '' }}>Cultural Festival</option>
                        <option value="religious" {{ old('category', $event->category) == 'religious' ? 'selected' : '' }}>Religious Poya / Festival</option>
                        <option value="seasonal" {{ old('category', $event->category) == 'seasonal' ? 'selected' : '' }}>Seasonal Attraction</option>
                        <option value="adventure" {{ old('category', $event->category) == 'adventure' ? 'selected' : '' }}>Adventure / Outdoor Event</option>
                    </select>
                </div>

                <!-- Location -->
                <div class="space-y-2">
                    <label for="location" class="block text-sm font-semibold text-slate-300">Location (District or City)</label>
                    <input type="text" name="location" id="location" value="{{ old('location', $event->location) }}" placeholder="e.g., Kandy, Island-wide" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500/50 transition">
                </div>
            </div>

            <!-- Date Configurations -->
            <div class="border-t border-slate-800/60 pt-6 space-y-4">
                <div>
                    <h3 class="text-sm font-bold uppercase tracking-wider text-emerald-400">Timing Configurations</h3>
                    <p class="text-xs text-slate-500 mt-1">Specify whether this is a single day event or spans a season/range (in MM-DD format, e.g. 04-13).</p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <!-- Date -->
                    <div class="space-y-2">
                        <label for="date" class="block text-sm font-semibold text-slate-300">Single Day (MM-DD)</label>
                        <input type="text" name="date" id="date" value="{{ old('date', $event->date) }}" placeholder="e.g., 04-13" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white font-mono placeholder-slate-600 focus:outline-none focus:border-emerald-500/50 transition">
                    </div>

                    <!-- Start -->
                    <div class="space-y-2">
                        <label for="start" class="block text-sm font-semibold text-slate-300">Start (MM-DD)</label>
                        <input type="text" name="start" id="start" value="{{ old('start', $event->start) }}" placeholder="e.g., 07-01" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white font-mono placeholder-slate-600 focus:outline-none focus:border-emerald-500/50 transition">
                    </div>

                    <!-- End -->
                    <div class="space-y-2">
                        <label for="end" class="block text-sm font-semibold text-slate-300">End (MM-DD)</label>
                        <input type="text" name="end" id="end" value="{{ old('end', $event->end) }}" placeholder="e.g., 08-31" class="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 px-4 text-white font-mono placeholder-slate-600 focus:outline-none focus:border-emerald-500/50 transition">
                    </div>
                </div>
            </div>

            <!-- Active Status Toggle -->
            <div class="border-t border-slate-800/60 pt-6 flex items-center justify-between">
                <div>
                    <label for="is_active" class="block text-sm font-semibold text-slate-300">Active Status</label>
                    <p class="text-xs text-slate-500">Only active events will be synced and displayed to mobile app users.</p>
                </div>
                <div class="flex items-center">
                    <input type="hidden" name="is_active" value="0">
                    <input type="checkbox" name="is_active" id="is_active" value="1" {{ old('is_active', $event->exists ? $event->is_active : true) ? 'checked' : '' }} class="w-5 h-5 rounded border-slate-800 text-emerald-500 focus:ring-emerald-500 bg-slate-900">
                </div>
            </div>

            <!-- Submit buttons -->
            <div class="border-t border-slate-800/60 pt-6 flex items-center justify-end gap-3">
                <a href="{{ route('admin.events.index') }}" class="text-sm font-semibold text-slate-400 hover:text-slate-200 transition py-2 px-4">
                    Cancel
                </a>
                <button type="submit" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold shadow-md shadow-emerald-950/20 transition duration-200 glow-effect">
                    {{ $event->exists ? "Save Changes" : "Publish Event" }}
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
