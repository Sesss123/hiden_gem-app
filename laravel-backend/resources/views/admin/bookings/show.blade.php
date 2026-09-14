@extends('admin.layout')

@section('content')
<div class="space-y-6 max-w-4xl mx-auto">
    <div class="flex items-center justify-between">
        <a href="{{ route('admin.bookings.index') }}" class="text-sm text-slate-400 hover:text-white flex items-center gap-1.5 w-fit transition">
            <i class="fa-solid fa-arrow-left"></i> Back to Bookings
        </a>
        <div class="text-xs text-slate-500 font-mono">
            Booking ID: <span class="text-slate-300 font-semibold">{{ $booking['id'] }}</span>
        </div>
    </div>

    @php
        $st = $booking['status'] ?? 'pending';
        $isTerminated = str_starts_with($st, 'cancelled') || in_array($st, ['declined', 'expired']);
        $steps = [
            ['key' => 'pending', 'label' => 'Requested', 'icon' => 'fa-paper-plane'],
            ['key' => 'accepted', 'label' => 'Quote Accepted', 'icon' => 'fa-handshake'],
            ['key' => 'session_ready', 'label' => 'Session Ready', 'icon' => 'fa-route'],
            ['key' => 'confirmed', 'label' => 'Payment Verified', 'icon' => 'fa-shield-check'],
            ['key' => 'completed', 'label' => 'Tour Completed', 'icon' => 'fa-circle-check'],
        ];

        $stepIndexes = ['pending' => 0, 'accepted' => 1, 'session_ready' => 2, 'confirmed' => 3, 'completed' => 4];
        $currentStepIdx = $stepIndexes[$st] ?? 0;
    @endphp

    <!-- State Progression Timeline -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800">
        <div class="flex items-center justify-between mb-5">
            <div>
                <h3 class="text-xs uppercase font-bold tracking-wider text-slate-400">Booking Lifecycle</h3>
                <p class="text-sm text-slate-300 mt-0.5">Live progression across tourist, guide, and escrow stages</p>
            </div>
            <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1 rounded-full border
                {{ $isTerminated ? 'bg-red-500/10 text-red-400 border-red-500/20' : ($st === 'completed' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                <span class="w-1.5 h-1.5 rounded-full {{ $isTerminated ? 'bg-red-400' : ($st === 'completed' ? 'bg-emerald-400' : 'bg-amber-400 animate-pulse') }}"></span>
                {{ ucfirst(str_replace('_', ' ', $st)) }}
            </span>
        </div>

        @if($isTerminated)
            <div class="bg-red-500/10 border border-red-500/20 rounded-xl p-4 flex items-center gap-3">
                <div class="w-8 h-8 rounded-lg bg-red-500/20 text-red-400 flex items-center justify-center shrink-0">
                    <i class="fa-solid fa-ban"></i>
                </div>
                <div>
                    <h4 class="text-xs font-bold text-red-300 uppercase tracking-wide">Booking Terminated</h4>
                    <p class="text-xs text-red-400/90 mt-0.5">This booking ended with status <span class="font-mono font-semibold">{{ $st }}</span>. Normal progression stopped.</p>
                </div>
            </div>
        @else
            <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
                @foreach($steps as $idx => $step)
                    @php
                        $isPast = $currentStepIdx > $idx;
                        $isCurrent = $currentStepIdx === $idx;
                    @endphp
                    <div class="p-3.5 rounded-xl border transition {{ $isCurrent ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300 shadow-sm' : ($isPast ? 'bg-slate-900/60 border-slate-800 text-slate-400' : 'bg-slate-950/40 border-slate-800/50 text-slate-600') }}">
                        <div class="flex items-center gap-2 mb-1.5">
                            <span class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold {{ $isCurrent ? 'bg-emerald-500 text-slate-950' : ($isPast ? 'bg-slate-800 text-emerald-400' : 'bg-slate-900 text-slate-600') }}">
                                @if($isPast)
                                    <i class="fa-solid fa-check text-[10px]"></i>
                                @else
                                    {{ $idx + 1 }}
                                @endif
                            </span>
                            <span class="text-xs font-semibold truncate">{{ $step['label'] }}</span>
                        </div>
                        <div class="text-[11px] {{ $isCurrent ? 'text-emerald-400/80 font-medium' : 'text-slate-500' }}">
                            {{ $isCurrent ? 'Active Stage' : ($isPast ? 'Completed' : 'Pending') }}
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>

    <!-- Human Identities Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Tourist Card -->
        <div class="glass-card p-5 rounded-2xl border border-slate-800 space-y-3">
            <div class="flex items-center justify-between">
                <span class="text-xs uppercase font-bold tracking-wider text-slate-400 flex items-center gap-1.5">
                    <i class="fa-solid fa-person-walking-luggage text-teal-400"></i> Tourist
                </span>
                <span class="text-[11px] font-mono px-2 py-0.5 rounded bg-teal-500/10 text-teal-300 border border-teal-500/20">{{ ucfirst($booking['touristRole'] ?? 'tourist') }}</span>
            </div>
            <div class="flex items-center gap-3 pt-1">
                <div class="w-11 h-11 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-300 font-bold text-base shrink-0">
                    {{ strtoupper(substr($booking['touristName'] ?? 'T', 0, 1)) }}
                </div>
                <div class="min-w-0 flex-1">
                    <div class="text-sm font-semibold text-white truncate">{{ $booking['touristName'] ?? 'Tourist' }}</div>
                    @if(!empty($booking['touristEmailMasked']))
                        <div class="text-xs text-slate-400 truncate">{{ $booking['touristEmailMasked'] }}</div>
                    @endif
                    <div class="text-[11px] text-slate-500 font-mono truncate mt-0.5" title="{{ $booking['touristId'] ?? '' }}">
                        UID: {{ $booking['touristId'] ?? 'N/A' }}
                    </div>
                </div>
            </div>
        </div>

        <!-- Guide Card -->
        <div class="glass-card p-5 rounded-2xl border border-slate-800 space-y-3">
            <div class="flex items-center justify-between">
                <span class="text-xs uppercase font-bold tracking-wider text-slate-400 flex items-center gap-1.5">
                    <i class="fa-solid fa-compass text-emerald-400"></i> Guide
                </span>
                <span class="text-[11px] font-mono px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-300 border border-emerald-500/20">{{ ucfirst($booking['guideRole'] ?? 'guide') }}</span>
            </div>
            <div class="flex items-center gap-3 pt-1">
                <div class="w-11 h-11 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-300 font-bold text-base shrink-0">
                    {{ strtoupper(substr($booking['guideName'] ?? 'G', 0, 1)) }}
                </div>
                <div class="min-w-0 flex-1">
                    <div class="text-sm font-semibold text-white truncate">{{ $booking['guideName'] ?? 'Guide' }}</div>
                    @if(!empty($booking['guideEmailMasked']))
                        <div class="text-xs text-slate-400 truncate">{{ $booking['guideEmailMasked'] }}</div>
                    @endif
                    <div class="text-[11px] text-slate-500 font-mono truncate mt-0.5" title="{{ $booking['guideId'] ?? '' }}">
                        UID: {{ $booking['guideId'] ?? 'N/A' }}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Booking Details & Financials -->
    <div class="glass-card p-6 rounded-2xl border border-slate-800 space-y-5">
        <h3 class="text-xs uppercase font-bold tracking-wider text-slate-400">Booking & Financial Specification</h3>
        
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm pt-2">
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Created At (SLST)</div>
                <div class="text-slate-200 text-xs flex items-center gap-1.5">
                    <i class="fa-regular fa-clock text-slate-500"></i>
                    {{ $booking['createdAtColombo'] ?? ($booking['createdAt'] ?? 'N/A') }}
                </div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Requested Tour Date</div>
                <div class="text-slate-200 text-xs flex items-center gap-1.5">
                    <i class="fa-regular fa-calendar text-slate-500"></i>
                    {{ $booking['requestedDateColombo'] ?? 'N/A' }}
                </div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Guest Count</div>
                <div class="text-slate-200 text-xs flex items-center gap-1.5">
                    <i class="fa-solid fa-users text-slate-500"></i>
                    {{ $booking['guestCount'] ?? '1' }} {{ ($booking['guestCount'] ?? 1) == 1 ? 'Guest' : 'Guests' }}
                </div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Quoted Price</div>
                <div class="text-slate-100 font-semibold text-sm">
                    @if(!empty($booking['quotedPrice']))
                        @if(!empty($booking['currencyLabel'])){{ $booking['currencyLabel'] }} {{ number_format($booking['quotedPrice'], 2) }}@else<span class="text-red-400">Currency unavailable</span>@endif
                    @else
                        <span class="text-slate-500 font-normal text-xs">Not quoted yet</span>
                    @endif
                </div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Escrow / Payout State</div>
                <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold border {{ $booking['priceStateClass'] ?? 'text-slate-400 bg-slate-800/40 border-slate-700' }}">
                    {{ $booking['priceStateLabel'] ?? ucfirst($booking['payoutStatus'] ?? 'pending') }}
                </span>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Payment ID</div>
                <div class="text-slate-300 font-mono text-xs">
                    {{ $booking['paymentId'] ?? 'N/A' }}
                </div>
            </div>

            @if(!empty($booking['notes']))
            <div class="col-span-2 md:col-span-3 bg-slate-900/50 p-3.5 rounded-xl border border-slate-800">
                <div class="text-xs text-slate-400 uppercase font-semibold mb-1">Tourist Requirements & Notes</div>
                <div class="text-slate-200 text-xs leading-relaxed">{{ $booking['notes'] }}</div>
            </div>
            @endif

            @if(!empty($booking['responseNote']))
            <div class="col-span-2 md:col-span-3 bg-slate-900/50 p-3.5 rounded-xl border border-slate-800">
                <div class="text-xs text-slate-400 uppercase font-semibold mb-1">Guide Response / Itinerary Note</div>
                <div class="text-slate-200 text-xs leading-relaxed">{{ $booking['responseNote'] }}</div>
            </div>
            @endif
        </div>

        @if($session)
        <div class="border-t border-slate-800 pt-4">
            <div class="text-xs text-slate-500 uppercase font-semibold mb-2">Linked Tour Session</div>
            <div class="bg-slate-900/50 rounded-xl p-4 text-sm border border-slate-800 flex items-center justify-between">
                <div>
                    <div class="text-slate-300 font-medium">Session Status: <span class="text-emerald-400">{{ ucfirst($session['status'] ?? 'unknown') }}</span></div>
                    <div class="text-xs text-slate-500 font-mono mt-1">ID: {{ $booking['linkedSessionId'] }}</div>
                </div>
                <span class="text-xs px-2.5 py-1 rounded bg-slate-800 text-slate-300 border border-slate-700">Active Live</span>
            </div>
        </div>
        @endif

        @if(!str_starts_with($st, 'cancelled') && !in_array($st, ['declined', 'expired', 'completed']))
        <div class="border-t border-slate-800 pt-4">
            <form action="{{ route('admin.bookings.cancel', $booking['id']) }}" method="POST" class="space-y-3"
                  onsubmit="return confirm('Cancel this booking as admin? This should be used for disputes/no-shows only.');">
                @csrf
                <label class="text-xs text-slate-400 uppercase font-semibold flex items-center gap-1.5">
                    <i class="fa-solid fa-triangle-exclamation text-red-400"></i> Admin Cancellation Action
                </label>
                <textarea name="reason" rows="2" required maxlength="1000"
                    class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-red-500/50 transition"
                    placeholder="Reason for admin cancellation (dispute, no-show, fraud, etc.)..."></textarea>
                <button type="submit" class="bg-red-600 hover:bg-red-500 text-white px-5 py-2.5 rounded-xl text-sm font-semibold shadow-md transition flex items-center gap-2">
                    <i class="fa-solid fa-ban"></i> Cancel Booking as Admin
                </button>
            </form>
        </div>
        @endif

        @if(($booking['payoutStatus'] ?? 'pending') === 'paid')
        <div class="border-t border-slate-800 pt-4">
            <form action="{{ route('admin.bookings.refund', $booking['id']) }}" method="POST" class="space-y-3"
                  onsubmit="return confirm('Refund this booking via PayHere? This calls PayHere\'s live refund API and cannot be undone from here.');">
                @csrf
                <label class="text-xs text-slate-400 uppercase font-semibold flex items-center gap-1.5">
                    <i class="fa-solid fa-rotate-left text-orange-400"></i> Admin Refund Gateway Action
                </label>
                <textarea name="reason" rows="2" required maxlength="1000"
                    class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-orange-500/50 transition"
                    placeholder="Reason for refund (dispute, cancellation, service issue, etc.)..."></textarea>
                <button type="submit" class="bg-orange-600 hover:bg-orange-500 text-white px-5 py-2.5 rounded-xl text-sm font-semibold shadow-md transition flex items-center gap-2">
                    <i class="fa-solid fa-rotate-left"></i> Refund Booking via PayHere
                </button>
            </form>
        </div>
        @endif
    </div>
</div>
@endsection
