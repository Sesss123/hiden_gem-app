@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-calendar-check text-emerald-400"></i> Tour Bookings Hub
            </h2>
            <p class="text-sm text-slate-400">Manage, verify, and resolve tourist-guide bookings across Sri Lanka.</p>
        </div>
        <div class="text-xs text-slate-500 font-mono">
            <i class="fa-solid fa-globe text-teal-400"></i> Timezone: Asia/Colombo (UTC+5:30)
        </div>
    </div>

    <!-- Status Filters -->
    <div class="flex flex-wrap gap-2">
        @foreach(['pending' => 'Pending', 'accepted' => 'Accepted', 'session_ready' => 'Session Ready', 'confirmed' => 'Payment Confirmed', 'completed' => 'Completed', 'declined' => 'Declined', 'expired' => 'Expired', 'all' => 'All Bookings'] as $key => $label)
            <a href="{{ route('admin.bookings.index', ['status' => $key]) }}"
               class="px-3.5 py-1.5 rounded-xl text-xs font-semibold transition {{ $status === $key ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-sm' : 'bg-slate-900/80 text-slate-400 border border-slate-800 hover:text-white hover:bg-slate-800/80' }}">
                {{ $label }}
            </a>
        @endforeach
    </div>

    <!-- Bookings Container -->
    <div class="glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl">
        <!-- Desktop Table View (Hidden on mobile < 768px) -->
        <div class="hidden md:block overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-5 py-4">Booking Details</th>
                        <th class="px-5 py-4">Tourist</th>
                        <th class="px-5 py-4">Guide</th>
                        <th class="px-5 py-4">Date & Party</th>
                        <th class="px-5 py-4">Financial State</th>
                        <th class="px-5 py-4">Status</th>
                        <th class="px-5 py-4 text-right sticky right-0 bg-slate-900/90 backdrop-blur-md">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($bookings as $booking)
                        <tr class="hover:bg-slate-900/40 transition">
                            <td class="px-5 py-4">
                                <div class="font-mono text-xs text-white font-semibold flex items-center gap-1.5">
                                    {{ \Illuminate\Support\Str::limit($booking['id'], 14) }}
                                    @if(!empty($booking['isPriority']))
                                        <span class="text-[9px] text-amber-400 bg-amber-500/10 px-1.5 py-0.5 rounded border border-amber-500/30">Priority</span>
                                    @endif
                                </div>
                                <div class="text-[11px] text-slate-400 mt-0.5">{{ $booking['createdAtColombo'] ?? 'N/A' }}</div>
                            </td>
                            <td class="px-5 py-4">
                                <div class="font-semibold text-white text-xs">{{ $booking['touristName'] }}</div>
                                @if(!empty($booking['touristEmailMasked']))
                                    <div class="text-[11px] text-slate-400 font-mono">{{ $booking['touristEmailMasked'] }}</div>
                                @endif
                            </td>
                            <td class="px-5 py-4">
                                <div class="font-semibold text-emerald-400 text-xs">{{ $booking['guideName'] }}</div>
                                @if(!empty($booking['guideEmailMasked']))
                                    <div class="text-[11px] text-slate-400 font-mono">{{ $booking['guideEmailMasked'] }}</div>
                                @endif
                            </td>
                            <td class="px-5 py-4 text-xs font-mono text-slate-300">
                                <div class="font-bold text-white">{{ $booking['requestedDateColombo'] ?? 'Date N/A' }}</div>
                                <div class="text-slate-400 text-[11px]">{{ $booking['guestCount'] ?? 1 }} guest(s)</div>
                            </td>
                            <td class="px-5 py-4 text-xs">
                                <div class="font-mono font-bold text-white">
                                    @if(!empty($booking['quotedPrice']))
                                        @if(!empty($booking['currencyLabel'])){{ $booking['currencyLabel'] }} {{ number_format($booking['quotedPrice'], 2) }}@else<span class="text-red-400">Currency unavailable</span>@endif
                                    @else
                                        <span class="text-slate-500 font-normal">Pending Quote</span>
                                    @endif
                                </div>
                                <span class="inline-block mt-0.5 px-2 py-0.5 rounded text-[10px] font-semibold border {{ $booking['priceStateClass'] ?? 'text-slate-400' }}">
                                    {{ $booking['priceStateLabel'] ?? 'Pending' }}
                                </span>
                            </td>
                            <td class="px-5 py-4">
                                @php $st = $booking['status'] ?? 'pending'; @endphp
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full border
                                    {{ str_starts_with($st, 'cancelled') || $st === 'declined' || $st === 'expired' ? 'bg-red-500/10 text-red-400 border-red-500/30' : ($st === 'completed' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30' : 'bg-amber-500/10 text-amber-400 border-amber-500/30') }}">
                                    <span class="w-1.5 h-1.5 rounded-full {{ str_starts_with($st, 'cancelled') || $st === 'declined' || $st === 'expired' ? 'bg-red-400' : ($st === 'completed' ? 'bg-emerald-400' : 'bg-amber-400') }}"></span>
                                    {{ ucfirst(str_replace('_', ' ', $st)) }}
                                </span>
                            </td>
                            <td class="px-5 py-4 text-right sticky right-0 bg-slate-900/90 backdrop-blur-md">
                                <a href="{{ route('admin.bookings.show', $booking['id']) }}" class="inline-flex items-center gap-1 bg-slate-800 hover:bg-slate-700 text-slate-200 hover:text-white px-3 py-1.5 rounded-lg text-xs font-semibold transition border border-slate-700" title="Review Booking">
                                    <i class="fa-solid fa-arrow-up-right-from-square text-[10px]"></i> View
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-12 text-center text-slate-500">
                                <i class="fa-solid fa-calendar-xmark text-3xl mb-2 text-slate-600"></i>
                                <p class="text-sm">No bookings found under status: <strong>{{ ucfirst(str_replace('_', ' ', $status)) }}</strong></p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Mobile Stacked Card View (< 768px) -->
        <div class="md:hidden divide-y divide-slate-800/60">
            @forelse($bookings as $booking)
                @php $st = $booking['status'] ?? 'pending'; @endphp
                <div class="p-4 space-y-3 hover:bg-slate-900/30 transition">
                    <div class="flex items-start justify-between gap-2">
                        <div>
                            <span class="font-mono text-xs font-bold text-white">{{ \Illuminate\Support\Str::limit($booking['id'], 14) }}</span>
                            <div class="text-[10px] text-slate-400">{{ $booking['createdAtColombo'] ?? 'N/A' }}</div>
                        </div>
                        <span class="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full border
                            {{ str_starts_with($st, 'cancelled') || $st === 'declined' || $st === 'expired' ? 'bg-red-500/10 text-red-400 border-red-500/30' : ($st === 'completed' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30' : 'bg-amber-500/10 text-amber-400 border-amber-500/30') }}">
                            {{ ucfirst(str_replace('_', ' ', $st)) }}
                        </span>
                    </div>

                    <div class="grid grid-cols-2 gap-2 text-xs bg-slate-900/60 p-2.5 rounded-xl border border-slate-800/60">
                        <div>
                            <span class="text-[10px] uppercase font-bold text-slate-500 block">Tourist</span>
                            <span class="font-semibold text-white truncate block">{{ $booking['touristName'] }}</span>
                            <span class="text-[10px] text-slate-400 font-mono">{{ $booking['touristEmailMasked'] ?? '' }}</span>
                        </div>
                        <div>
                            <span class="text-[10px] uppercase font-bold text-slate-500 block">Guide</span>
                            <span class="font-semibold text-emerald-400 truncate block">{{ $booking['guideName'] }}</span>
                            <span class="text-[10px] text-slate-400 font-mono">{{ $booking['guideEmailMasked'] ?? '' }}</span>
                        </div>
                    </div>

                    <div class="flex items-center justify-between text-xs pt-1">
                        <div>
                            <span class="text-slate-400 font-mono">{{ $booking['requestedDateColombo'] ?? 'Date N/A' }}</span>
                            <span class="text-slate-500 text-[11px]">({{ $booking['guestCount'] ?? 1 }} guests)</span>
                        </div>
                        <div class="text-right">
                            <div class="font-mono font-bold text-white">
                                @if(!empty($booking['quotedPrice']))
                                    @if(!empty($booking['currencyLabel'])){{ $booking['currencyLabel'] }} {{ number_format($booking['quotedPrice'], 2) }}@else<span class="text-red-400">Currency unavailable</span>@endif
                                @else
                                    <span class="text-slate-500">Unquoted</span>
                                @endif
                            </div>
                        </div>
                    </div>

                    <div class="pt-1 flex items-center justify-between gap-2">
                        <span class="inline-block px-2 py-0.5 rounded text-[10px] font-semibold border {{ $booking['priceStateClass'] ?? 'text-slate-400' }}">
                            {{ $booking['priceStateLabel'] ?? 'Pending' }}
                        </span>
                        <a href="{{ route('admin.bookings.show', $booking['id']) }}" class="bg-slate-800 text-slate-200 px-3 py-1.5 rounded-lg text-xs font-semibold border border-slate-700 flex items-center gap-1">
                            Details <i class="fa-solid fa-chevron-right text-[9px]"></i>
                        </a>
                    </div>
                </div>
            @empty
                <div class="p-8 text-center text-slate-500 space-y-2">
                    <i class="fa-solid fa-calendar-xmark text-3xl text-slate-600"></i>
                    <p class="text-sm">No bookings found.</p>
                </div>
            @endforelse
        </div>
    </div>
</div>
@endsection
