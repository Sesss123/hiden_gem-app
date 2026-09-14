@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold text-white">Travel Hazard Alerts</h2>
        <p class="text-sm text-slate-400">Create verified, time-limited landslide, flood and road-closure alerts.</p>
    </div>

    @if(session('success'))<div class="rounded-xl border border-emerald-700 bg-emerald-950/40 p-3 text-emerald-300">{{ session('success') }}</div>@endif

    <form method="POST" action="{{ route('admin.travel-alerts.store') }}" class="glass-card rounded-2xl p-5 grid grid-cols-1 md:grid-cols-2 gap-4">
        @csrf
        <select name="type" required class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white"><option value="landslide">Landslide</option><option value="flood">Flood</option><option value="closed_road">Closed road</option><option value="monsoon">Monsoon</option></select>
        <select name="level" required class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white"><option value="1">Level 1 - Yellow</option><option value="2">Level 2 - Amber</option><option value="3">Level 3 - Red</option></select>
        <input name="title" maxlength="160" required placeholder="Alert title" class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white">
        <input name="source" maxlength="120" required placeholder="Verified source (NBRO / DMC / RDA)" class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white">
        <input name="districts[]" placeholder="District" class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white">
        <input name="river_basins[]" placeholder="River basin (optional)" class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white">
        <input type="datetime-local" name="starts_at" required class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white">
        <input type="datetime-local" name="expires_at" required class="bg-slate-900 border border-slate-700 rounded-xl p-3 text-white">
        <textarea name="message" maxlength="4000" required placeholder="Traveler guidance" class="md:col-span-2 bg-slate-900 border border-slate-700 rounded-xl p-3 text-white"></textarea>
        <button class="md:col-span-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl p-3 font-semibold">Save draft</button>
    </form>

    <div class="glass-card rounded-2xl overflow-x-auto">
        <table class="w-full text-left text-sm">
            <thead class="text-slate-400"><tr><th class="p-4">Alert</th><th>Level</th><th>Source</th><th>Expiry</th><th>Status</th><th class="p-4">Actions</th></tr></thead>
            <tbody class="divide-y divide-slate-800">
            @forelse($alerts as $alert)
                <tr class="text-slate-200"><td class="p-4"><div class="font-semibold">{{ $alert->title }}</div><div class="text-xs text-slate-500">{{ $alert->type }}</div></td><td>{{ $alert->level }}</td><td>{{ $alert->source }}</td><td>{{ $alert->expires_at?->format('Y-m-d H:i') }}</td><td>{{ $alert->is_active ? 'Published' : 'Draft/Inactive' }}</td><td class="p-4 flex gap-2">@if(!$alert->is_active)<form method="POST" action="{{ route('admin.travel-alerts.publish', $alert) }}">@csrf<button class="text-emerald-400">Publish</button></form>@endif<form method="POST" action="{{ route('admin.travel-alerts.destroy', $alert) }}">@csrf @method('DELETE')<button class="text-red-400">Deactivate</button></form></td></tr>
            @empty<tr><td colspan="6" class="p-8 text-center text-slate-500">No alerts yet.</td></tr>@endforelse
            </tbody>
        </table>
    </div>
    {{ $alerts->links() }}
</div>
@endsection
