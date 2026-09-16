@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-crown text-amber-400"></i> Premium Subscriptions & Integrity Scanner
            </h2>
            <p class="text-sm text-slate-400">Verified RevenueCat subscription synchronizer and production entitlement security scanner.</p>
        </div>
        @if($invalidOrMockCount > 0)
            <div class="px-4 py-2 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300 text-xs font-semibold flex items-center gap-2 animate-pulse">
                <i class="fa-solid fa-triangle-exclamation text-red-400 text-sm"></i>
                <span>{{ $invalidOrMockCount }} Anomaly / Mock Entitlement(s) Detected!</span>
            </div>
        @endif
    </div>

    <!-- Stat Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="glass-card p-5 rounded-2xl border border-slate-800">
            <div class="text-xs text-slate-400 uppercase font-semibold mb-1">Premium Claims Scanned</div>
            <div class="text-3xl font-bold text-white">{{ $totalPremiumCount }}</div>
        </div>
        <div class="glass-card p-5 rounded-2xl border border-slate-800">
            <div class="text-xs text-slate-400 uppercase font-semibold mb-1">Verified Active Premium</div>
            <div class="text-3xl font-bold text-emerald-400">{{ $verifiedPremiumCount }}</div>
        </div>
        <div class="glass-card p-5 rounded-2xl border border-slate-800">
            <div class="text-xs text-slate-400 uppercase font-semibold mb-1">Integrity Scanner Status</div>
            @if($invalidOrMockCount > 0)
                <div class="text-2xl font-bold text-red-400 flex items-center gap-1.5">
                    <i class="fa-solid fa-circle-xmark text-lg"></i> {{ $invalidOrMockCount }} Invalid
                </div>
            @else
                <div class="text-2xl font-bold text-emerald-400 flex items-center gap-1.5">
                    <i class="fa-solid fa-shield-check text-lg"></i> 100% Clean
                </div>
            @endif
        </div>
        <div class="glass-card p-5 rounded-2xl border border-slate-800">
            <div class="text-xs text-slate-400 uppercase font-semibold mb-2">By Verified Plan</div>
            <div class="space-y-1">
                @forelse($planCounts as $plan => $count)
                    <div class="flex justify-between text-xs">
                        <span class="text-slate-300 font-mono">{{ ucfirst($plan) }}</span>
                        <span class="text-slate-400 font-mono">{{ $count }}</span>
                    </div>
                @empty
                    <span class="text-slate-500 text-xs">No premium users yet.</span>
                @endforelse
            </div>
        </div>
    </div>

    <!-- Search Bar -->
    <div class="glass-card p-4 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4 border border-slate-800">
        <form action="{{ route('admin.subscriptions.index') }}" method="GET" class="w-full flex flex-col md:flex-row gap-4">
            <div class="flex-1 relative">
                <i class="fa-solid fa-magnifying-glass absolute left-4 top-3 text-slate-400"></i>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search by name, email, or UID..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-11 pr-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50 transition">
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

    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">User</th>
                        <th class="px-6 py-4">Plan & Status</th>
                        <th class="px-6 py-4">Expires</th>
                        <th class="px-6 py-4">Firebase UID</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($premiumUsers as $user)
                        <tr class="hover:bg-slate-900/30 transition {{ !empty($user['_is_mock_or_invalid']) ? 'bg-red-950/10' : '' }}">
                            <td class="px-6 py-4">
                                <div class="font-semibold text-white flex items-center gap-2">
                                    {{ $user['displayName'] ?? 'Unnamed Traveler' }}
                                    @if(!empty($user['_is_mock_or_invalid']))
                                        <span class="bg-red-500 text-white text-[9px] font-extrabold px-1.5 py-0.5 rounded uppercase">Unverified / Mock</span>
                                    @endif
                                </div>
                                <div class="text-xs text-slate-400">{{ $user['email'] ?? 'No email provided' }}</div>
                            </td>
                            <td class="px-6 py-4">
                                @if(!empty($user['_is_mock_or_invalid']))
                                    <span class="bg-red-500/20 text-red-400 text-xs px-2.5 py-1 rounded-full font-bold border border-red-500/40 inline-flex items-center gap-1.5">
                                        <i class="fa-solid fa-triangle-exclamation"></i>
                                        {{ $user['premiumPlan'] ?? 'invalid_plan' }}
                                    </span>
                                @else
                                    <span class="bg-amber-500/10 text-amber-400 text-xs px-2.5 py-1 rounded-full font-medium border border-amber-500/20 inline-flex items-center gap-1">
                                        <i class="fa-solid fa-crown text-[10px]"></i>
                                        {{ ucfirst($user['premiumPlan'] ?? 'unknown') }}
                                    </span>
                                @endif
                                @if(!empty($user['_integrity_reasons']))
                                    <ul class="mt-2 text-[10px] text-red-300 list-disc pl-4">
                                        @foreach($user['_integrity_reasons'] as $reason)<li>{{ $reason }}</li>@endforeach
                                    </ul>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-slate-300 font-mono text-xs">
                                @if(!empty($user['premiumExpiresAt']))
                                    <span class="{{ !empty($user['_is_expired']) ? 'text-red-400 font-bold' : (!empty($user['_is_expiring_soon']) ? 'text-amber-400' : 'text-slate-300') }}">
                                        {{ $user['premiumExpiresAt'] }}
                                    </span>
                                @else
                                    <span class="text-slate-500">Permanent / No Expiry</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-slate-500 font-mono text-xs">
                                <span title="{{ $user['id'] }}">{{ \Illuminate\Support\Str::limit($user['id'], 18) }}</span>
                            </td>
                            <td class="px-6 py-4 text-right">
                                @if(!empty($user['_is_mock_or_invalid']))
                                <button type="button" data-uid="{{ $user['id'] }}" data-name="{{ $user['displayName'] ?? 'User' }}" data-plan="{{ $user['premiumPlan'] ?? 'unknown' }}"
                                    onclick="openRevokeModal(this)"
                                    class="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 transition">
                                    <i class="fa-solid fa-user-xmark"></i> Revoke
                                </button>
                                @else
                                    <span class="text-xs text-emerald-400"><i class="fa-solid fa-shield-check"></i> Verified</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-6 py-10 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-crown text-3xl text-slate-600"></i>
                                    <span>No premium users found matching criteria.</span>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Revoke Entitlement Confirmation Modal -->
<div id="revoke-modal" class="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 hidden flex items-center justify-center p-4">
    <div class="glass-card max-w-md w-full p-6 rounded-2xl border border-red-500/40 shadow-2xl space-y-4 animate-fadeIn">
        <div class="flex items-center gap-3 text-red-400">
            <div class="w-10 h-10 rounded-xl bg-red-500/20 flex items-center justify-center shrink-0">
                <i class="fa-solid fa-shield-halved text-xl"></i>
            </div>
            <div>
                <h3 class="font-bold text-white text-base">Revoke Premium Entitlement</h3>
                <p class="text-xs text-slate-400">Security enforcement & audit logged action</p>
            </div>
        </div>

        <p class="text-xs text-slate-300 leading-relaxed">
            Are you sure you want to revoke premium access for <strong id="modal-user-name" class="text-white"></strong> (<span id="modal-user-plan" class="font-mono text-amber-400"></span>)?
            This atomically revokes the Firestore user and linked webhook record. It does not cancel billing in RevenueCat/Google Play; cancel the store subscription first when one exists.
        </p>

        <form id="revoke-form" method="POST" action="">
            @csrf
            <div class="space-y-3">
                <div>
                    <label class="block text-xs font-semibold text-slate-400 mb-1">Revocation Reason (Mandatory Audit Requirement):</label>
                    <input type="text" name="reason" required maxlength="500" placeholder="e.g. Mock test dev account cleanup / RevenueCat mismatch"
                        class="w-full bg-slate-900 border border-slate-700 rounded-xl p-2.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-red-500">
                </div>

                <div class="flex items-center justify-end gap-2 pt-2">
                    <button type="button" onclick="closeRevokeModal()" class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white transition">
                        Cancel
                    </button>
                    <button type="submit" class="px-5 py-2 rounded-xl text-xs font-bold bg-red-600 hover:bg-red-500 text-white shadow-lg shadow-red-900/30 transition flex items-center gap-1.5">
                        <i class="fa-solid fa-ban"></i> Confirm Revocation
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
    // Built via Laravel's own route() helper with a placeholder token, so a
    // future change to the admin.subscriptions.revoke path is caught by
    // route:list / a 404 at the template level instead of silently breaking
    // this one hand-built URL.
    const REVOKE_URL_TEMPLATE = @json(route('admin.subscriptions.revoke', ['uid' => 'UID_PLACEHOLDER']));

    function openRevokeModal(button) {
        const uid = button.dataset.uid;
        document.getElementById('modal-user-name').innerText = button.dataset.name;
        document.getElementById('modal-user-plan').innerText = button.dataset.plan;
        document.getElementById('revoke-form').action = REVOKE_URL_TEMPLATE.replace('UID_PLACEHOLDER', encodeURIComponent(uid));
        document.getElementById('revoke-modal').classList.remove('hidden');
    }

    function closeRevokeModal() {
        document.getElementById('revoke-modal').classList.add('hidden');
    }
</script>
@endsection
