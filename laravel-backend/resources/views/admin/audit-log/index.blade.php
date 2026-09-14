@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <!-- Header & Filter Bar -->
    <div class="glass-card p-6 rounded-2xl flex flex-col lg:flex-row items-start lg:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-3">
                <h2 class="text-xl font-bold text-white flex items-center gap-2">
                    <i class="fa-solid fa-shield-halved text-emerald-400"></i> Admin Audit Log
                </h2>
                <span class="inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-800 text-slate-400 border border-slate-700">
                    {{ number_format($totalLogs ?? $logs->total()) }} total records
                </span>
            </div>
            <p class="text-xs text-slate-400 mt-1">Who did what — logins, approvals, rejections, deletions, role changes.</p>
        </div>

        <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
            @if(false)
                <!-- Bulk Clean Dropdown & Button -->
                <form action="{{ route('admin.audit-log.clear') }}" method="POST" class="flex items-center gap-1.5"
                      onsubmit="return confirm('Are you sure you want to clean audit logs for the selected timeframe? This action is permanent and cannot be undone.');">
                    @csrf
                    @method('DELETE')
                    <div class="flex items-center bg-slate-900/90 border border-slate-700/80 rounded-xl p-1 shadow-inner">
                        <select name="timeframe" class="bg-transparent text-xs text-slate-300 font-medium px-2.5 py-1.5 focus:outline-none cursor-pointer">
                            <option value="7_days" class="bg-slate-900 text-slate-200">Older than 7 days</option>
                            <option value="30_days" selected class="bg-slate-900 text-slate-200">Older than 30 days</option>
                            <option value="60_days" class="bg-slate-900 text-slate-200">Older than 60 days</option>
                            <option value="90_days" class="bg-slate-900 text-slate-200">Older than 90 days</option>
                            <option value="all" class="bg-slate-900 text-red-400 font-bold">⚠️ Clear All Logs</option>
                        </select>
                        <button type="submit" class="bg-red-500/20 hover:bg-red-500/30 text-red-300 hover:text-white border border-red-500/30 px-3 py-1.5 rounded-lg text-xs font-semibold transition flex items-center gap-1.5" title="Execute log cleanup">
                            <i class="fa-solid fa-trash-can text-[11px]"></i> Clean
                        </button>
                    </div>
                </form>
            @endif

            <!-- Search & Action Filters -->
            <form action="{{ route('admin.audit-log.index') }}" method="GET" class="flex flex-wrap items-center gap-2 flex-1 lg:flex-initial">
                <div class="relative flex-1 sm:w-48">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                        <i class="fa-solid fa-magnifying-glass text-xs"></i>
                    </span>
                    <input type="text" name="actor" value="{{ request('actor') }}" placeholder="Search actor..."
                        class="w-full pl-9 pr-3 py-2 bg-slate-900/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
                </div>

                <input type="text" name="action" value="{{ request('action') }}" placeholder="Action (e.g. place.approved)"
                    class="flex-1 sm:w-44 pl-3 pr-3 py-2 bg-slate-900/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">

                <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-white px-3.5 py-2 rounded-xl text-xs font-semibold border border-slate-700 transition">
                    Filter
                </button>

                @if(request('action') || request('actor'))
                    <a href="{{ route('admin.audit-log.index') }}" class="text-xs text-slate-400 hover:text-white px-2 py-2" title="Reset filters">
                        <i class="fa-solid fa-xmark"></i>
                    </a>
                @endif
            </form>
        </div>
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
                        <th class="py-4 px-6 hidden md:table-cell">IP</th>
                        <th class="py-4 px-6">Details</th>
                        @if(false)
                            <th class="py-4 px-6 text-right">Actions</th>
                        @endif
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
                                $isFailure = str_contains($log->action, 'failed') || str_contains($log->action, 'rejected') || str_contains($log->action, 'banned') || str_contains($log->action, 'deleted') || str_contains($log->action, 'cleared');
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
                        <td class="py-3 px-6 text-slate-400 font-mono text-xs hidden md:table-cell">{{ $log->ip_address ?? '—' }}</td>
                        <td class="py-3 px-6 text-slate-400 text-xs max-w-xs">
                            @if(!empty($log->details))
                                <pre class="whitespace-pre-wrap break-words text-[11px] text-slate-500">{{ \Illuminate\Support\Str::limit(is_string($log->details) ? $log->details : json_encode($log->details), 150) }}</pre>
                            @else
                                <span class="text-slate-600">—</span>
                            @endif
                        </td>
                        @if(false)
                            <td class="py-3 px-6 text-right">
                                <form action="{{ route('admin.audit-log.destroy', $log->id) }}" method="POST" class="inline-block"
                                      onsubmit="return confirm('Are you sure you want to permanently delete this audit log entry?');">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-slate-800 hover:bg-red-600 text-slate-400 hover:text-white transition shadow border border-slate-700/60 hover:border-red-500/60" title="Delete Log">
                                        <i class="fa-solid fa-trash-can text-xs"></i>
                                    </button>
                                </form>
                            </td>
                        @endif
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-clipboard-list text-3xl mb-3 block opacity-40"></i>
                            No audit log entries found.
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
