@extends('admin.layout')

@section('content')
<div class="space-y-6 max-w-4xl mx-auto">
    <a href="{{ route('admin.bookings.index') }}" class="text-sm text-slate-400 hover:text-white flex items-center gap-1.5 w-fit">
        <i class="fa-solid fa-arrow-left"></i> Back to Bookings
    </a>

    <div class="glass-card p-6 rounded-2xl space-y-5">
        <div class="flex items-start justify-between gap-4">
            <div>
                <h2 class="text-xl font-bold text-white">Booking Details</h2>
                <p class="text-xs text-slate-500 font-mono mt-1">{{ $booking['id'] }}</p>
            </div>
            @php $st = $booking['status'] ?? 'pending'; @endphp
            <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1 rounded-full border
                {{ str_starts_with($st, 'cancelled') || $st === 'declined' || $st === 'expired' ? 'bg-red-500/10 text-red-400 border-red-500/20' : ($st === 'completed' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                {{ ucfirst(str_replace('_', ' ', $st)) }}
            </span>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm border-t border-slate-800 pt-4">
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Tourist</div>
                <div class="text-slate-200 font-mono text-xs">{{ $booking['touristId'] ?? 'N/A' }}</div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Guide</div>
                <div class="text-slate-200 font-mono text-xs">{{ $booking['guideId'] ?? 'N/A' }}</div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Requested Date</div>
                <div class="text-slate-200">{{ $booking['requestedDate'] ?? 'N/A' }}</div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Guests</div>
                <div class="text-slate-200">{{ $booking['guestCount'] ?? 'N/A' }}</div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Quoted Price</div>
                <div class="text-slate-200">
                    @if(!empty($booking['quotedPrice']))
                        {{ $booking['currency'] ?? 'LKR' }} {{ number_format($booking['quotedPrice'], 2) }}
                    @else
                        <span class="text-slate-600">Not quoted</span>
                    @endif
                </div>
            </div>
            <div>
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Payout Status</div>
                <div class="text-slate-200">{{ ucfirst($booking['payoutStatus'] ?? 'pending') }}</div>
            </div>
            @if(!empty($booking['notes']))
            <div class="col-span-2 md:col-span-3">
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Notes</div>
                <div class="text-slate-300">{{ $booking['notes'] }}</div>
            </div>
            @endif
            @if(!empty($booking['responseNote']))
            <div class="col-span-2 md:col-span-3">
                <div class="text-xs text-slate-500 uppercase font-semibold mb-1">Response Note</div>
                <div class="text-slate-300">{{ $booking['responseNote'] }}</div>
            </div>
            @endif
        </div>

        @if($session)
        <div class="border-t border-slate-800 pt-4">
            <div class="text-xs text-slate-500 uppercase font-semibold mb-2">Linked Tour Session</div>
            <div class="bg-slate-900/50 rounded-xl p-4 text-sm">
                <div class="text-slate-300">Status: {{ ucfirst($session['status'] ?? 'unknown') }}</div>
                <div class="text-xs text-slate-500 font-mono mt-1">{{ $booking['linkedSessionId'] }}</div>
            </div>
        </div>
        @endif

        @if(!str_starts_with($st, 'cancelled') && !in_array($st, ['declined', 'expired', 'completed']))
        <div class="border-t border-slate-800 pt-4">
            <form action="{{ route('admin.bookings.cancel', $booking['id']) }}" method="POST" class="space-y-3"
                  onsubmit="return confirm('Cancel this booking as admin? This should be used for disputes/no-shows only.');">
                @csrf
                <label class="text-xs text-slate-500 uppercase font-semibold">Admin Cancellation Reason</label>
                <textarea name="reason" rows="2" required maxlength="1000"
                    class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-red-500/50 transition"
                    placeholder="Reason for admin cancellation (dispute, no-show, fraud, etc.)..."></textarea>
                <button type="submit" class="bg-red-600 hover:bg-red-500 text-white px-5 py-2.5 rounded-xl text-sm font-semibold shadow-md transition flex items-center gap-2">
                    <i class="fa-solid fa-ban"></i> Cancel Booking
                </button>
            </form>
        </div>
        @endif
    </div>
</div>
@endsection
