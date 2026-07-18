@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-triangle-exclamation text-red-500"></i> Incident Reports
            </h2>
            <p class="text-sm text-slate-400">SOS alerts and manually filed safety incidents.</p>
        </div>
    </div>

    <!-- Status Tabs -->
    <div class="flex flex-wrap gap-2">
        @foreach(['open' => 'Open', 'under_review' => 'Under Review', 'escalated' => 'Escalated', 'resolved' => 'Resolved', 'dismissed' => 'Dismissed', 'all' => 'All'] as $key => $label)
            <a href="{{ route('admin.incidents.index', ['status' => $key]) }}"
               class="px-4 py-2 rounded-xl text-sm font-semibold transition {{ $status === $key ? 'bg-red-500/20 text-red-300 border border-red-500/40' : 'bg-slate-900 text-slate-400 border border-slate-800 hover:text-white' }}">
                {{ $label }}
            </a>
        @endforeach
    </div>

    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">Incident</th>
                        <th class="px-6 py-4">Type / Severity</th>
                        <th class="px-6 py-4">Reported By</th>
                        <th class="px-6 py-4">Filed</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($incidents as $incident)
                        <tr class="hover:bg-slate-900/30 transition">
                            <td class="px-6 py-5">
                                <div class="font-bold text-white">{{ $incident['title'] ?? 'Untitled' }}</div>
                                <div class="text-xs text-slate-400 max-w-xs truncate mt-0.5">{{ $incident['description'] ?? '' }}</div>
                                <div class="text-[10px] text-slate-600 font-mono mt-1">{{ $incident['incidentNumber'] ?? $incident['id'] }}</div>
                            </td>
                            <td class="px-6 py-5">
                                <span class="text-xs text-slate-300">{{ ucfirst(str_replace('_', ' ', $incident['type'] ?? 'unknown')) }}</span>
                                <div class="mt-1">
                                    @php $sev = $incident['severity'] ?? 'low'; @endphp
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border
                                        {{ $sev === 'critical' ? 'bg-red-500/10 text-red-400 border-red-500/20' : ($sev === 'high' ? 'bg-orange-500/10 text-orange-400 border-orange-500/20' : 'bg-slate-800 text-slate-400 border-slate-700') }}">
                                        {{ ucfirst($sev) }}
                                    </span>
                                </div>
                            </td>
                            <td class="px-6 py-5 text-slate-300">
                                <i class="fa-solid fa-user text-slate-500 mr-1.5"></i> {{ ucfirst($incident['reportedByRole'] ?? 'unknown') }}
                            </td>
                            <td class="px-6 py-5 text-slate-400 font-mono text-xs">
                                {{ \Illuminate\Support\Str::of($incident['createdAt'] ?? '')->limit(16, '') }}
                            </td>
                            <td class="px-6 py-5">
                                @php $st = $incident['status'] ?? 'open'; @endphp
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border
                                    {{ $st === 'resolved' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : ($st === 'dismissed' ? 'bg-slate-800 text-slate-500 border-slate-700' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                                    <span class="w-1.5 h-1.5 rounded-full {{ $st === 'resolved' ? 'bg-emerald-400' : ($st === 'dismissed' ? 'bg-slate-500' : 'bg-amber-400') }}"></span>
                                    {{ ucfirst(str_replace('_', ' ', $st)) }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-right">
                                <a href="{{ route('admin.incidents.show', $incident['id']) }}" class="text-slate-400 hover:text-red-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="View">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-10 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-shield-heart text-3xl text-slate-600"></i>
                                    <span>No incidents in this category.</span>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
