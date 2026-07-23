@extends('admin.layout')

@section('content')
<div class="space-y-6 max-w-4xl mx-auto">
    <a href="{{ route('admin.incidents.index') }}" class="text-sm text-slate-400 hover:text-white flex items-center gap-1.5 w-fit">
        <i class="fa-solid fa-arrow-left"></i> Back to Incidents
    </a>

    <div class="glass-card p-6 rounded-2xl space-y-5">
        <div class="flex items-start justify-between gap-4">
            <div>
                <h2 class="text-xl font-bold text-white">{{ $incident['title'] ?? 'Untitled Incident' }}</h2>
                <p class="text-xs text-slate-500 font-mono mt-1">{{ $incident['incidentNumber'] ?? $incident['id'] }}</p>
            </div>
            @php $sev = $incident['severity'] ?? 'low'; @endphp
            <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1 rounded-full border
                {{ $sev === 'critical' ? 'bg-red-500/10 text-red-400 border-red-500/20' : ($sev === 'high' ? 'bg-orange-500/10 text-orange-400 border-orange-500/20' : 'bg-slate-800 text-slate-400 border-slate-700') }}">
                {{ ucfirst($sev) }} severity
            </span>
        </div>

        <p class="text-sm text-slate-300 leading-relaxed">{{ $incident['description'] ?? 'No description provided.' }}</p>

        <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm border-t border-slate-800 pt-4">
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Type</div>
                <div class="text-slate-200">{{ ucfirst(str_replace('_', ' ', $incident['type'] ?? 'unknown')) }}</div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Reported By</div>
                <div class="text-slate-200">{{ ucfirst($incident['reportedByRole'] ?? 'unknown') }}</div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Filed</div>
                <div class="text-slate-200 font-mono text-xs">{{ $incident['createdAt'] ?? 'N/A' }}</div>
            </div>
            @if(!empty($incident['lat']) && !empty($incident['lng']))
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Location</div>
                <a href="https://www.google.com/maps/search/?api=1&query={{ $incident['lat'] }},{{ $incident['lng'] }}" target="_blank" class="text-emerald-400 hover:underline text-xs">
                    {{ $incident['lat'] }}, {{ $incident['lng'] }} <i class="fa-solid fa-up-right-from-square text-[10px]"></i>
                </a>
            </div>
            @endif
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Session</div>
                <div class="text-slate-200 font-mono text-xs">{{ $incident['sessionId'] ?? 'N/A' }}</div>
            </div>
        </div>

        @if(!empty($incident['timelineEvents']))
        <div class="border-t border-slate-800 pt-4">
            <div class="text-xs text-slate-500 uppercase font-semibold mb-3">Timeline</div>
            <div class="space-y-3">
                @foreach($incident['timelineEvents'] as $event)
                    <div class="flex gap-3 text-sm">
                        <div class="w-1.5 h-1.5 rounded-full bg-emerald-500 mt-1.5 flex-shrink-0"></div>
                        <div>
                            <div class="text-slate-200">{{ $event['description'] ?? '' }}</div>
                            <div class="text-xs text-slate-500 font-mono">{{ $event['timestamp'] ?? '' }}</div>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
        @endif

        @if(($incident['status'] ?? 'open') === 'resolved')
            <div class="border-t border-slate-800 pt-4 bg-emerald-500/5 -mx-6 -mb-6 px-6 py-4 rounded-b-2xl">
                <div class="text-xs text-emerald-400 uppercase font-semibold mb-1">Resolved</div>
                <p class="text-sm text-slate-300">{{ $incident['resolutionNote'] ?? '' }}</p>
                <p class="text-xs text-slate-500 mt-1">by {{ $incident['resolvedBy'] ?? 'unknown' }} on {{ $incident['resolvedAt'] ?? '' }}</p>
            </div>
        @else
            <div class="border-t border-slate-800 pt-4 space-y-3">
                <!-- Two sibling forms, not nested — nested <form> tags are
                     invalid HTML5 and browsers silently un-nest them during
                     parsing, which can break field association unpredictably. -->
                <form action="{{ route('admin.incidents.resolve', $incident['id']) }}" method="POST" class="space-y-3">
                    @csrf
                    <label class="text-xs text-slate-500 uppercase font-semibold">Resolution Note</label>
                    <textarea name="resolution_note" rows="3" required maxlength="1000"
                        class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50 transition"
                        placeholder="Describe how this incident was resolved..."></textarea>
                    <div class="flex gap-2">
                        <button type="submit" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-5 py-2.5 rounded-xl text-sm font-semibold shadow-md transition flex items-center gap-2">
                            <i class="fa-solid fa-circle-check"></i> Mark Resolved
                        </button>
                    </div>
                </form>
                <form action="{{ route('admin.incidents.dismiss', $incident['id']) }}" method="POST" onsubmit="return confirm('Dismiss this incident (e.g. false alarm)?');">
                    @csrf
                    <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-slate-300 px-5 py-2.5 rounded-xl text-sm font-semibold border border-slate-700 transition">
                        Dismiss
                    </button>
                </form>
            </div>
        @endif
    </div>
</div>
@endsection
