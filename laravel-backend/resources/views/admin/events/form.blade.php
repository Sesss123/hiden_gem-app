@extends('admin.layout')

@section('content')
@php
    $isEdit = $event->exists;
    $action = $isEdit ? route('admin.events.update', $event->id) : route('admin.events.store');
@endphp

<div class="max-w-3xl mx-auto space-y-6">
    <div class="flex items-center justify-between">
        <div>
            <a href="{{ route('admin.events.index') }}" class="text-xs font-semibold text-slate-400 hover:text-white transition flex items-center gap-1 mb-1">
                <i class="fa-solid fa-arrow-left"></i> Back to Events
            </a>
            <h2 class="text-2xl font-bold text-white flex items-center gap-2">
                <i class="fa-solid {{ $isEdit ? 'fa-pen-to-square' : 'fa-circle-plus' }} text-emerald-400"></i>
                {{ $isEdit ? 'Edit Event: ' . $event->name : 'Create New Calendar Event' }}
            </h2>
        </div>
        @if($isEdit)
            <span class="text-xs bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-xl font-mono text-teal-300">
                Sync Version: v{{ $event->sync_version }}
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
            <button type="button" data-tab="info" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-circle-info"></i> Event Info
            </button>
            <button type="button" data-tab="schedule" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-regular fa-calendar"></i> Schedule
            </button>
            <button type="button" data-tab="media" class="form-tab-btn shrink-0 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition">
                <i class="fa-solid fa-images"></i> Media
            </button>
        </div>
    </div>

    <form action="{{ $action }}" method="POST" enctype="multipart/form-data" class="space-y-6">
        @csrf
        @if($isEdit)
            @method('PUT')
        @endif

        <!-- Tab 1: Event Info -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="info">
            <h3 class="text-sm font-semibold text-emerald-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-solid fa-circle-info"></i> Event Details
            </h3>

            <div class="space-y-2">
                <label for="name" class="block text-xs font-semibold text-slate-300">Event Name <span class="text-red-500">*</span></label>
                <input type="text" name="name" id="name" value="{{ old('name', $event->name) }}" required placeholder="e.g., Sinhala & Tamil New Year" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
            </div>

            <div class="space-y-2">
                <label for="description" class="block text-xs font-semibold text-slate-300">Description</label>
                <textarea name="description" id="description" rows="4" placeholder="Briefly describe the cultural significance, activities, or history of this event..." class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">{{ old('description', $event->description) }}</textarea>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label for="category" class="block text-xs font-semibold text-slate-300 mb-1">Category <span class="text-red-500">*</span></label>
                    <select name="category" id="category" required class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500">
                        <option value="">Select Category</option>
                        <option value="cultural" {{ old('category', $event->category) == 'cultural' ? 'selected' : '' }}>Cultural Festival</option>
                        <option value="religious" {{ old('category', $event->category) == 'religious' ? 'selected' : '' }}>Religious Poya / Festival</option>
                        <option value="seasonal" {{ old('category', $event->category) == 'seasonal' ? 'selected' : '' }}>Seasonal Attraction</option>
                        <option value="adventure" {{ old('category', $event->category) == 'adventure' ? 'selected' : '' }}>Adventure / Outdoor Event</option>
                    </select>
                </div>

                <div>
                    <label for="location" class="block text-xs font-semibold text-slate-300 mb-1">Location (District or City)</label>
                    <input type="text" name="location" id="location" value="{{ old('location', $event->location) }}" placeholder="e.g., Kandy, Island-wide" class="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                </div>
            </div>
        </div>

        <!-- Tab 2: Schedule -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="schedule">
            <h3 class="text-sm font-semibold text-teal-400 uppercase tracking-wider border-b border-slate-800 pb-2 flex items-center gap-2">
                <i class="fa-regular fa-calendar"></i> Timing Configuration
            </h3>
            <p class="text-xs text-slate-500 -mt-2">Specify whether this is a single day event or spans a season/range. Events in this catalog are annual/recurring, so pick any year below — only the month and day are saved.</p>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label for="date_picker" class="block text-xs font-semibold text-slate-300 mb-1">Single Day</label>
                    <input type="date" id="date_picker" class="event-date-picker w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500" data-target="date" style="color-scheme: dark;">
                    <input type="hidden" name="date" id="date" value="{{ old('date', $event->date) }}">
                </div>
                <div>
                    <label for="start_picker" class="block text-xs font-semibold text-slate-300 mb-1">Start</label>
                    <input type="date" id="start_picker" class="event-date-picker w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500" data-target="start" style="color-scheme: dark;">
                    <input type="hidden" name="start" id="start" value="{{ old('start', $event->start) }}">
                </div>
                <div>
                    <label for="end_picker" class="block text-xs font-semibold text-slate-300 mb-1">End</label>
                    <input type="date" id="end_picker" class="event-date-picker w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-emerald-500" data-target="end" style="color-scheme: dark;">
                    <input type="hidden" name="end" id="end" value="{{ old('end', $event->end) }}">
                </div>
            </div>

            <div class="border-t border-slate-800/60 pt-6 flex items-center justify-between">
                <div>
                    <label for="is_active" class="block text-xs font-semibold text-slate-300">Active Status</label>
                    <p class="text-[11px] text-slate-500">Only active, approved events are synced and displayed to mobile app users.</p>
                </div>
                <div class="flex items-center">
                    <input type="hidden" name="is_active" value="0">
                    <input type="checkbox" name="is_active" id="is_active" value="1" {{ old('is_active', $event->exists ? $event->is_active : true) ? 'checked' : '' }} class="w-5 h-5 rounded border-slate-800 text-emerald-500 focus:ring-emerald-500 bg-slate-900">
                </div>
            </div>
        </div>

        <!-- Tab 3: Media Gallery & Uploads -->
        <div class="form-tab-panel glass-card p-6 rounded-2xl space-y-4 border border-slate-800" data-panel="media">
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
                        <input type="file" id="images_input" name="images[]" multiple accept="image/*" class="hidden">
                    </label>
                </div>
                <!-- Client-side preview only — confirms the browser actually picked
                     up the files before the form is submitted (same pattern as
                     admin/places/form.blade.php). Not yet uploaded to the server;
                     the real upload happens on form submit. -->
                <div id="images_preview_wrap" class="mt-3 hidden">
                    <p id="images_preview_count" class="text-[11px] font-semibold text-emerald-400 mb-2"></p>
                    <div id="images_preview_grid" class="grid grid-cols-2 md:grid-cols-4 gap-3"></div>
                </div>
            </div>

            @if($isEdit && $event->images->isNotEmpty())
                <div class="mt-4">
                    <label class="block text-xs font-semibold text-slate-400 mb-2">Existing Gallery Photos ({{ $event->images->count() }})</label>
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                        @foreach($event->images as $img)
                            <div class="relative group bg-slate-900 rounded-xl p-2 border {{ $img->is_cover ? 'border-emerald-500 shadow-lg shadow-emerald-950/50' : 'border-slate-800' }}">
                                <img src="{{ $img->thumb_path }}" class="w-full h-24 object-cover rounded-lg">
                                @if($img->is_cover)
                                    <span class="absolute top-3 left-3 bg-emerald-500 text-white text-[9px] font-bold px-1.5 py-0.5 rounded shadow">COVER</span>
                                @endif

                                {{-- content_manager has full unreviewed edit rights over Events
                                     (unlike Places, where edits get reset to pending for
                                     re-review), so both roles get image controls here. --}}
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
            <a href="{{ route('admin.events.index') }}" class="px-5 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-sm font-semibold transition">
                Cancel
            </a>
            <button type="submit" class="px-6 py-2.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-sm font-bold shadow-lg shadow-emerald-900/50 transition glow-effect">
                <i class="fa-solid fa-check mr-1"></i> {{ $isEdit ? 'Save Changes' : 'Publish Event' }}
            </button>
        </div>
    </form>

    <!-- Hidden forms for image actions -->
    @if($isEdit)
        @foreach($event->images as $img)
            <form id="cover-form-{{ $img->id }}" action="{{ route('admin.event-images.cover', $img->id) }}" method="POST" class="hidden">
                @csrf
            </form>
            <form id="delete-form-{{ $img->id }}" action="{{ route('admin.event-images.delete', $img->id) }}" method="POST" class="hidden">
                @csrf
                @method('DELETE')
            </form>
        @endforeach
    @endif
</div>

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
    // the first invalid field, same pattern as places/form.blade.php.
    let initialTab = 'info';
    const firstInvalidName = @json($errors->any() ? array_key_first($errors->toArray()) : null);
    if (firstInvalidName) {
        const fieldToTab = {
            name: 'info', description: 'info', category: 'info', location: 'info',
            date: 'schedule', start: 'schedule', end: 'schedule', is_active: 'schedule',
            'images.0': 'media', images: 'media',
        };
        initialTab = fieldToTab[firstInvalidName] || 'info';
    }

    showTab(initialTab);

    // The DB stores MM-DD only (events are annual/recurring, no year), but
    // <input type="date"> needs a full date to render as a real calendar
    // widget — a fixed dummy leap year (2024) lets Feb 29 events still be
    // picked. The hidden text input (the one actually submitted/validated
    // server-side against /^[0-1][0-9]-[0-3][0-9]$/) is kept in sync from it.
    const DUMMY_YEAR = '2024';
    document.querySelectorAll('.event-date-picker').forEach(function(picker) {
        const targetId = picker.dataset.target;
        const hiddenInput = document.getElementById(targetId);
        if (!hiddenInput) return;

        // Pre-fill the visible picker from any existing MM-DD value
        // (edit mode, or a validation-error redisplay).
        if (hiddenInput.value && /^\d{2}-\d{2}$/.test(hiddenInput.value)) {
            picker.value = DUMMY_YEAR + '-' + hiddenInput.value;
        }

        picker.addEventListener('change', function() {
            if (!picker.value) {
                hiddenInput.value = '';
                return;
            }
            // picker.value is always YYYY-MM-DD per the date input spec.
            hiddenInput.value = picker.value.slice(5);
        });
    });

    // Client-side preview of picked-but-not-yet-uploaded files (same pattern
    // as admin/places/form.blade.php) — an admin previously had no way to
    // confirm a file selection registered until saving and reopening the
    // edit page to see "Existing Gallery Photos".
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

            previewCount.textContent = files.length + ' file' + (files.length === 1 ? '' : 's') + ' selected — not saved yet, click "' + (@json($isEdit) ? 'Save Changes' : 'Create Event') + '" below to upload.';
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
