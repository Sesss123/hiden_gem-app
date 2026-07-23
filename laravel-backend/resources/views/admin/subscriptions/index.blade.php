@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-crown text-amber-500"></i> Premium Subscriptions
        </h2>
        <p class="text-sm text-slate-400">Read-only overview — sourced from Firestore, the RevenueCat webhook's source of truth. No manual grant/revoke here by design (see code comment).</p>
    </div>

    <!-- Stat Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="glass-card p-5 rounded-2xl">
            <div class="text-xs text-slate-400 uppercase font-semibold mb-1">Total Premium Users</div>
            <div class="text-3xl font-bold text-white">{{ $totalPremiumCount }}</div>
        </div>
        <div class="glass-card p-5 rounded-2xl">
            <div class="text-xs text-slate-400 uppercase font-semibold mb-1">Expiring Within 7 Days</div>
            <div class="text-3xl font-bold {{ $expiringSoonCount > 0 ? 'text-amber-400' : 'text-white' }}">{{ $expiringSoonCount }}</div>
        </div>
        <div class="glass-card p-5 rounded-2xl">
            <div class="text-xs text-slate-400 uppercase font-semibold mb-2">By Plan</div>
            <div class="space-y-1">
                @forelse($planCounts as $plan => $count)
                    <div class="flex justify-between text-sm">
                        <span class="text-slate-300">{{ ucfirst($plan) }}</span>
                        <span class="text-slate-400 font-mono">{{ $count }}</span>
                    </div>
                @empty
                    <span class="text-slate-500 text-sm">No premium users yet.</span>
                @endforelse
            </div>
        </div>
    </div>

    <!-- Search Bar -->
    <div class="glass-card p-4 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
        <form action="{{ route('admin.subscriptions.index') }}" method="GET" class="w-full flex flex-col md:flex-row gap-4">
            <div class="flex-1 relative">
                <i class="fa-solid fa-magnifying-glass absolute left-4 top-3 text-slate-400"></i>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search by name or email..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-11 pr-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50 transition">
            </div>
            <div class="flex gap-2">
                <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-white px-5 py-2.5 rounded-xl text-sm font-semibold border border-slate-700 transition">
                    Filter
                </button>
                @if(request('search'))
                    <a href="{{ route('admin.subscriptions.index') }}" class="bg-slate-900 hover:bg-slate-850 text-slate-400 border border-slate-800 px-5 py-2.5 rounded-xl text-sm font-semibold transition flex items-center justify-center">
                        Clear
                    </a>
                @endif
            </div>
        </form>
    </div>

    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">User</th>
                        <th class="px-6 py-4">Plan</th>
                        <th class="px-6 py-4">Expires</th>
                        <th class="px-6 py-4">Firebase UID</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($premiumUsers as $user)
                        <tr class="hover:bg-slate-900/30 transition">
                            <td class="px-6 py-5">
                                <div class="font-semibold text-white">{{ $user['displayName'] ?? 'Unnamed' }}</div>
                                <div class="text-xs text-slate-400">{{ $user['email'] ?? '' }}</div>
                            </td>
                            <td class="px-6 py-5">
                                <span class="bg-amber-500/10 text-amber-400 text-xs px-2.5 py-1 rounded-full font-medium border border-amber-500/20">
                                    {{ ucfirst($user['premiumPlan'] ?? 'unknown') }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-slate-300 font-mono text-xs">
                                {{ $user['premiumExpiresAt'] ?? 'N/A' }}
                            </td>
                            <td class="px-6 py-5 text-slate-500 font-mono text-xs">
                                {{ $user['id'] }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="px-6 py-10 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-crown text-3xl text-slate-600"></i>
                                    <span>No premium users found.</span>
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
