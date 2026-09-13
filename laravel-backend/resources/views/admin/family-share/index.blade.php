@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-people-arrows text-sky-400"></i> Family Share
        </h2>
        <p class="text-sm text-slate-400">Monitor encrypted trip-sharing links and revoke access. Decryption keys and plaintext trip status are never available here.</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="glass-card p-5 rounded-2xl"><div class="text-xs text-slate-400 uppercase font-semibold">Total links</div><div class="text-3xl font-bold text-white mt-1">{{ $totalCount }}</div></div>
        <div class="glass-card p-5 rounded-2xl"><div class="text-xs text-slate-400 uppercase font-semibold">Active</div><div class="text-3xl font-bold text-emerald-400 mt-1">{{ $activeCount }}</div></div>
        <div class="glass-card p-5 rounded-2xl"><div class="text-xs text-slate-400 uppercase font-semibold">Stale sync</div><div class="text-3xl font-bold {{ $staleCount ? 'text-amber-400' : 'text-white' }} mt-1">{{ $staleCount }}</div></div>
    </div>

    <form method="GET" action="{{ route('admin.family-share.index') }}" class="glass-card p-4 rounded-2xl flex flex-col md:flex-row gap-3">
        <input name="search" value="{{ request('search') }}" placeholder="Recipient, tourist UID or session ID" class="flex-1 bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-white">
        <select name="status" class="bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-white">
            <option value="">All statuses</option>
            <option value="active" @selected(request('status') === 'active')>Active</option>
            <option value="stale" @selected(request('status') === 'stale')>Stale sync</option>
            <option value="inactive" @selected(request('status') === 'inactive')>Inactive / expired</option>
        </select>
        <button class="bg-slate-800 hover:bg-slate-700 px-5 py-2.5 rounded-xl text-sm font-semibold">Filter</button>
    </form>

    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead><tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase">
                    <th class="px-5 py-4">Recipient</th><th class="px-5 py-4">Session / owner</th><th class="px-5 py-4">Status</th><th class="px-5 py-4">Expiry / sync</th><th class="px-5 py-4 text-right">Action</th>
                </tr></thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                @forelse($links as $link)
                    <tr class="hover:bg-slate-900/30">
                        <td class="px-5 py-4"><div class="font-semibold text-white">{{ $link['recipientName'] ?? 'Unnamed' }}</div><div class="text-xs text-slate-500">{{ (int) ($link['viewCount'] ?? 0) }} views</div></td>
                        <td class="px-5 py-4 font-mono text-xs"><div class="text-slate-300">{{ $link['sessionId'] ?? '—' }}</div><div class="text-slate-500">{{ $link['touristId'] ?? '—' }}</div></td>
                        <td class="px-5 py-4">
                            @if($link['_stale']) <span class="text-amber-400">Stale sync</span>
                            @elseif($link['_active']) <span class="text-emerald-400">Active</span>
                            @else <span class="text-slate-500">Inactive</span> @endif
                        </td>
                        <td class="px-5 py-4 text-xs text-slate-400"><div>{{ $link['_expiresAt'] ? $link['_expiresAt']->format('Y-m-d H:i').' UTC' : 'Invalid expiry' }}</div><div>Sync: {{ $link['_lastSyncedAt']?->diffForHumans() ?? 'Never' }}</div></td>
                        <td class="px-5 py-4 text-right">
                            @if($link['_active'])
                            <form method="POST" action="{{ route('admin.family-share.revoke', $link['id']) }}" onsubmit="return confirm('Revoke this link immediately?')">
                                @csrf
                                <button class="text-red-400 hover:text-red-300 font-semibold">Revoke</button>
                            </form>
                            @else <span class="text-slate-600">—</span> @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="px-6 py-12 text-center text-slate-500">No Family Share links found.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
