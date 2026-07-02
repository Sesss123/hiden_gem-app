@extends('admin.layout')

@section('title', 'Job Scheduler & Controls - Hidden Gems SL')
@section('header', 'Automated Job Scheduler & Server Controls')

@section('content')
<div class="space-y-6">
    <!-- Status Banner -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-2xl bg-indigo-500/20 text-indigo-400 border border-indigo-500/30 flex items-center justify-center text-2xl font-bold shadow-lg">
                ⏱️
            </div>
            <div>
                <div class="flex items-center gap-2">
                    <h2 class="text-xl font-bold text-white">Background Automation Engine</h2>
                    <span class="px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider {{ $pythonOnline ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30' : 'bg-amber-500/20 text-amber-300 border border-amber-500/30' }}">
                        {{ $pythonOnline ? 'Active & Polling' : 'Local Standby' }}
                    </span>
                </div>
                <p class="text-sm text-slate-400 mt-0.5">
                    Managing recurring RAG knowledge index updates, weather monitoring, and database backups.
                </p>
            </div>
        </div>
        <div>
            <form action="{{ route('admin.scheduler.backup') }}" method="POST">
                @csrf
                <button type="submit" class="px-4 py-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl text-sm font-semibold transition shadow-lg shadow-emerald-900/30 flex items-center gap-2">
                    <span>💾</span> Trigger Instant Database Backup
                </button>
            </form>
        </div>
    </div>

    <!-- Alert Messages -->
    @if(session('success'))
        <div class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center gap-3">
            <span>✅</span>
            <span class="text-sm font-medium">{{ session('success') }}</span>
        </div>
    @endif
    @if(session('error'))
        <div class="p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 flex items-center gap-3">
            <span>⚠️</span>
            <span class="text-sm font-medium">{{ session('error') }}</span>
        </div>
    @endif

    <!-- Scheduled Jobs List -->
    <div class="glass-card rounded-2xl border border-slate-800 overflow-hidden">
        <div class="p-6 border-b border-slate-800">
            <h3 class="font-bold text-lg text-white">Configured Automation Jobs</h3>
        </div>

        @if(empty($jobs))
            <!-- Default Built-in Jobs Table when Python offline / empty -->
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="border-b border-slate-800 bg-slate-900/50 text-slate-400 text-xs uppercase tracking-wider font-semibold">
                            <th class="p-4">Job Name</th>
                            <th class="p-4">Schedule (Cron)</th>
                            <th class="p-4">Target Subsystem</th>
                            <th class="p-4">Status</th>
                            <th class="p-4 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-800/60 text-sm text-slate-300">
                        <tr class="hover:bg-slate-800/30 transition">
                            <td class="p-4 font-semibold text-white flex items-center gap-3">
                                <span class="w-8 h-8 rounded-lg bg-indigo-500/20 text-indigo-400 flex items-center justify-center font-bold">🧠</span>
                                Vector RAG Index Refresher
                            </td>
                            <td class="p-4 font-mono text-xs text-indigo-300">0 */6 * * * (Every 6h)</td>
                            <td class="p-4 text-slate-400">Python Neural Engine</td>
                            <td class="p-4"><span class="px-2 py-0.5 bg-emerald-500/20 text-emerald-300 rounded text-xs font-semibold border border-emerald-500/30">Active</span></td>
                            <td class="p-4 text-right">
                                <button disabled class="px-3 py-1 bg-slate-800 text-slate-500 rounded text-xs font-semibold">Run Now</button>
                            </td>
                        </tr>
                        <tr class="hover:bg-slate-800/30 transition">
                            <td class="p-4 font-semibold text-white flex items-center gap-3">
                                <span class="w-8 h-8 rounded-lg bg-cyan-500/20 text-cyan-400 flex items-center justify-center font-bold">🌧️</span>
                                Monsoon & Weather Alert Polling
                            </td>
                            <td class="p-4 font-mono text-xs text-cyan-300">*/30 * * * * (Every 30m)</td>
                            <td class="p-4 text-slate-400">weather_service.py</td>
                            <td class="p-4"><span class="px-2 py-0.5 bg-emerald-500/20 text-emerald-300 rounded text-xs font-semibold border border-emerald-500/30">Active</span></td>
                            <td class="p-4 text-right">
                                <button disabled class="px-3 py-1 bg-slate-800 text-slate-500 rounded text-xs font-semibold">Run Now</button>
                            </td>
                        </tr>
                        <tr class="hover:bg-slate-800/30 transition">
                            <td class="p-4 font-semibold text-white flex items-center gap-3">
                                <span class="w-8 h-8 rounded-lg bg-amber-500/20 text-amber-400 flex items-center justify-center font-bold">📦</span>
                                SQLite Delta Sync Snapshot Generator
                            </td>
                            <td class="p-4 font-mono text-xs text-amber-300">0 0 * * * (Daily at Midnight)</td>
                            <td class="p-4 text-slate-400">Laravel PlaceSync</td>
                            <td class="p-4"><span class="px-2 py-0.5 bg-emerald-500/20 text-emerald-300 rounded text-xs font-semibold border border-emerald-500/30">Active</span></td>
                            <td class="p-4 text-right">
                                <button disabled class="px-3 py-1 bg-slate-800 text-slate-500 rounded text-xs font-semibold">Run Now</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        @else
            <!-- Live Jobs from Python API -->
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="border-b border-slate-800 bg-slate-900/50 text-slate-400 text-xs uppercase tracking-wider font-semibold">
                            <th class="p-4">Job ID</th>
                            <th class="p-4">Name</th>
                            <th class="p-4">Schedule</th>
                            <th class="p-4">Next Run</th>
                            <th class="p-4 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-800/60 text-sm text-slate-300">
                        @foreach($jobs as $job)
                            <tr class="hover:bg-slate-800/30 transition">
                                <td class="p-4 font-mono text-xs text-indigo-400">{{ $job['id'] }}</td>
                                <td class="p-4 font-semibold text-white">{{ $job['name'] }}</td>
                                <td class="p-4 font-mono text-xs">{{ $job['trigger'] ?? 'Interval' }}</td>
                                <td class="p-4 text-xs text-slate-400">{{ $job['next_run'] ?? 'N/A' }}</td>
                                <td class="p-4 text-right">
                                    <form action="{{ route('admin.scheduler.run', $job['id']) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" class="px-3 py-1 bg-indigo-600 hover:bg-indigo-500 text-white rounded text-xs font-semibold transition">▶ Run Now</button>
                                    </form>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>
</div>
@endsection
