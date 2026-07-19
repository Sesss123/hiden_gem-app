@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <!-- Header & Filter Bar -->
    <div class="glass-card p-6 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
        <div>
            <h2 class="text-xl font-bold text-white flex items-center gap-2">
                <i class="fa-solid fa-shield-halved text-emerald-400"></i> Admin Audit Log
            </h2>
            <p class="text-xs text-slate-400 mt-0.5">Who did what — logins, approvals, rejections, deletions, role changes.</p>
        </div>

        <form action="{{ route('admin.audit-log.index') }}" method="GET" class="flex flex-wrap items-center gap-3 w-full md:w-auto">
            <div class="relative flex-1 md:w-56">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                    <i class="fa-solid fa-magnifying-glass text-xs"></i>
                </span>
                <input type="text" name="actor" value="{{ request('actor') }}" placeholder="Search by actor name/email..."
                    class="w-full pl-9 pr-4 py-2 bg-slate-900/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
            </div>

            <input type="text" name="action" value="{{ request('action') }}" placeholder="Filter by action (e.g. place.approved)"
                class="flex-1 md:w-56 pl-4 pr-4 py-2 bg-slate-900/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">

            <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-xl text-xs font-semibold border border-slate-700 transition">
                Filter
            </button>

            @if(request('action') || request('actor'))
                <a href="{{ route('admin.audit-log.index') }}" class="text-xs text-slate-400 hover:text-white px-2 py-2">
                    <i class="fa-solid fa-xmark"></i> Clear
                </a>
            @endif
        </form>
    </div>

    <!-- Audit Log Table -->
    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 text-slate-400 text-xs font-semibold uppercase tracking-wider border-b border-slate-800">
                        <th class="py-4 px-6">Timestamp</th>
                        <th class="py-4 px-6">Actor</th>
                        <th class="py-4 px-6">Action</th>
                        <th class="py-4 px-6">Target</th>
                        <th class="py-4 px-6">IP</th>
                        <th class="py-4 px-6">Details</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-sm">
                    @forelse($logs as $log)
                    <tr class="hover:bg-slate-800/40 transition duration-150">
                        <td class="py-3 px-6 text-slate-400 font-mono text-xs whitespace-nowrap">
                            {{ $log->created_at ? $log->created_at->format('Y-m-d H:i:s') : 'N/A' }}
                        </td>
                        <td class="py-3 px-6">
                            @if($log->actor_name || $log->actor_email)
                                <div class="font-medium text-white text-xs">{{ $log->actor_name }}</div>
                                <div class="text-[11px] text-slate-500">{{ $log->actor_email }}</div>
                            @else
                                <span class="text-slate-600 italic text-xs">System / Unknown</span>
                            @endif
                        </td>
                        <td class="py-3 px-6">
                            @php
                                $isFailure = str_contains($log->action, 'failed') || str_contains($log->action, 'rejected') || str_contains($log->action, 'banned') || str_contains($log->action, 'deleted');
                            @endphp
                            <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border font-mono
                                {{ $isFailure ? 'bg-red-500/10 text-red-400 border-red-500/20' : 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' }}">
                                {{ $log->action }}
                            </span>
                        </td>
                        <td class="py-3 px-6 text-slate-300 text-xs">
                            @if($log->target_type)
                                <span class="inline-flex items-center gap-1 bg-slate-900 px-2.5 py-1 rounded-lg text-xs text-slate-300 border border-slate-800">
                                    {{ $log->target_type }} #{{ $log->target_id }}
                                </span>
                            @else
                                <span class="text-slate-600">—</span>
                            @endif
                        </td>
                        <td class="py-3 px-6 text-slate-400 font-mono text-xs">{{ $log->ip_address ?? '—' }}</td>
                        <td class="py-3 px-6 text-slate-400 text-xs max-w-xs">
                            @if(!empty($log->details))
                                <pre class="whitespace-pre-wrap break-words text-[11px] text-slate-500">{{ \Illuminate\Support\Str::limit(json_encode($log->details), 150) }}</pre>
                            @else
                                <span class="text-slate-600">—</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-clipboard-list text-3xl mb-3 block opacity-40"></i>
                            No audit log entries yet.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($logs->hasPages())
            <div class="p-4 border-t border-slate-800 bg-slate-900/40">
                {{ $logs->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
