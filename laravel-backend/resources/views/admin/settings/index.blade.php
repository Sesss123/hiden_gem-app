@extends('admin.layout')

@section('content')
<div class="space-y-6 max-w-5xl">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-sliders text-emerald-400"></i> App Remote Settings
        </h2>
        <p class="text-sm text-slate-400">Control live mobile application features, advertisements, and client configurations without releasing app updates to Google Play or Apple App Store.</p>
    </div>

    @if(session('success'))
        <div class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-sm flex items-center gap-3">
            <i class="fa-solid fa-circle-check text-lg"></i>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    <!-- Master Ads Switch Card -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800/80 shadow-xl">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div class="flex items-start gap-4">
                <div class="w-14 h-14 rounded-2xl bg-gradient-to-tr from-amber-500/20 to-orange-500/20 border border-amber-500/30 flex items-center justify-center shrink-0 shadow-inner">
                    <i class="fa-solid fa-rectangle-ad text-2xl text-amber-400"></i>
                </div>
                <div>
                    <div class="flex items-center gap-3 mb-1">
                        <h3 class="text-lg font-bold text-white">Google AdMob Advertisements</h3>
                        @if($isAdsEnabled)
                            <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/20 border border-emerald-500/40 text-emerald-400 flex items-center gap-1.5">
                                <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                                ACTIVE (ON)
                            </span>
                        @else
                            <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-red-500/20 border border-red-500/40 text-red-400 flex items-center gap-1.5">
                                <span class="w-2 h-2 rounded-full bg-red-400"></span>
                                PAUSED (OFF)
                            </span>
                        @endif
                    </div>
                    <p class="text-xs text-slate-400 max-w-xl leading-relaxed">
                        Master switch controlling Banner Ads, Native Ads, Interstitials, and Rewarded Video Ads across Android and iOS builds.
                        When set to <strong class="text-slate-200">PAUSED</strong>, the mobile app hides all ads immediately, and rewarded feature unlocks (like AR and AI tools) are granted automatically without forcing users to wait.
                    </p>

                    @if($adsSetting && $adsSetting->updater)
                        <p class="text-[11px] text-slate-500 mt-3 flex items-center gap-1.5 font-medium">
                            <i class="fa-solid fa-clock-rotate-left"></i>
                            Last updated by <span class="text-slate-400">{{ $adsSetting->updater->name }}</span> ({{ $adsSetting->updated_at->diffForHumans() }})
                        </p>
                    @endif
                </div>
            </div>

            <!-- Toggle Form -->
            <form action="{{ route('admin.settings.ads.toggle') }}" method="POST" class="shrink-0">
                @csrf
                <input type="hidden" name="enabled" value="{{ $isAdsEnabled ? '0' : '1' }}">
                <button type="submit"
                    class="px-5 py-2.5 rounded-xl text-sm font-semibold transition-all duration-200 shadow-lg flex items-center gap-2.5 {{ $isAdsEnabled ? 'bg-red-500/20 hover:bg-red-500/30 text-red-300 border border-red-500/40 shadow-red-950/30' : 'bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold shadow-emerald-950/40' }}">
                    @if($isAdsEnabled)
                        <i class="fa-solid fa-power-off"></i> Turn Ads OFF
                    @else
                        <i class="fa-solid fa-play"></i> Turn Ads ON
                    @endif
                </button>
            </form>
        </div>
    </div>

    <!-- API Client Details -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="glass-card p-5 rounded-2xl border border-slate-800/80">
            <h4 class="text-xs text-slate-400 uppercase font-semibold mb-2 flex items-center gap-2">
                <i class="fa-solid fa-network-wired text-sky-400"></i> Public Remote Endpoint
            </h4>
            <div class="bg-slate-900/90 border border-slate-800 rounded-xl p-3 font-mono text-xs text-emerald-400 flex items-center justify-between">
                <span>GET /api/v1/config/ads</span>
                <span class="text-[10px] text-slate-500 uppercase bg-slate-800 px-2 py-0.5 rounded">Cache: 2 min</span>
            </div>
            <p class="text-[11px] text-slate-500 mt-2">Flutter mobile app polls this endpoint at launch and caches the result locally in SharedPreferences.</p>
        </div>

        <div class="glass-card p-5 rounded-2xl border border-slate-800/80">
            <h4 class="text-xs text-slate-400 uppercase font-semibold mb-2 flex items-center gap-2">
                <i class="fa-solid fa-shield-halved text-teal-400"></i> Failover & Offline Guarantee
            </h4>
            <ul class="text-xs text-slate-400 space-y-1.5 list-disc list-inside">
                <li>Zero tourist lockouts: Rewarded items unlock automatically if ads are paused.</li>
                <li>Offline caching: Retains last known state if traveler has no signal.</li>
                <li>Admin audit: Every toggle action is recorded with IP and admin identity.</li>
            </ul>
        </div>
    </div>

    <!-- Recent Setting Audit Logs -->
    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800/80">
        <div class="px-5 py-4 border-b border-slate-800 flex items-center justify-between">
            <h3 class="font-semibold text-sm text-white flex items-center gap-2">
                <i class="fa-solid fa-history text-slate-400"></i> Recent Configuration Audit History
            </h3>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="border-b border-slate-800/60 bg-slate-900/40 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                        <th class="py-3 px-4">Admin</th>
                        <th class="py-3 px-4">Action</th>
                        <th class="py-3 px-4">Details</th>
                        <th class="py-3 px-4">Timestamp</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-xs">
                    @forelse($recentSettingsLogs as $log)
                        <tr class="hover:bg-slate-800/30 transition">
                            <td class="py-3 px-4 font-medium text-white">
                                {{ $log->actor_name ?? 'System' }}
                                <div class="text-[10px] text-slate-500">{{ $log->actor_email ?? '-' }}</div>
                            </td>
                            <td class="py-3 px-4 text-emerald-400 font-mono">{{ $log->action }}</td>
                            <td class="py-3 px-4 text-slate-300">{{ $log->details }}</td>
                            <td class="py-3 px-4 text-slate-400 whitespace-nowrap">{{ $log->created_at->format('M d, Y H:i:s') }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="py-6 text-center text-slate-500">
                                No app setting changes recorded yet.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
