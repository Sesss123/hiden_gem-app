@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-calendar-check text-emerald-500"></i> Bookings
        </h2>
        <p class="text-sm text-slate-400">Tour booking requests between tourists and guides.</p>
    </div>

    <div class="flex flex-wrap gap-2">
        @foreach(['pending' => 'Pending', 'accepted' => 'Accepted', 'session_ready' => 'Session Ready', 'completed' => 'Completed', 'declined' => 'Declined', 'expired' => 'Expired', 'all' => 'All'] as $key => $label)
            <a href="{{ route('admin.bookings.index', ['status' => $key]) }}"
               class="px-4 py-2 rounded-xl text-sm font-semibold transition {{ $status === $key ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40' : 'bg-slate-900 text-slate-400 border border-slate-800 hover:text-white' }}">
                {{ $label }}
            </a>
        @endforeach
    </div>

    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">Booking</th>
                        <th class="px-6 py-4">Tourist / Guide</th>
                        <th class="px-6 py-4">Date / Guests</th>
                        <th class="px-6 py-4">Price</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($bookings as $booking)
                        <tr class="hover:bg-slate-900/30 transition">
                            <td class="px-6 py-5">
                                <div class="text-xs text-slate-500 font-mono">{{ $booking['id'] }}</div>
                                @if(!empty($booking['isPriority']))
                                    <span class="inline-flex items-center gap-1 text-[10px] text-amber-400 font-semibold mt-1"><i class="fa-solid fa-bolt"></i> Priority</span>
                                @endif
                            </td>
                            <td class="px-6 py-5 text-slate-300 text-xs">
                                <div>T: {{ \Illuminate\Support\Str::limit($booking['touristId'] ?? 'N/A', 16) }}</div>
                                <div>G: {{ \Illuminate\Support\Str::limit($booking['guideId'] ?? 'N/A', 16) }}</div>
                            </td>
                            <td class="px-6 py-5 text-slate-300 text-xs font-mono">
                                {{ $booking['requestedDate'] ?? 'N/A' }}<br>
                                <span class="text-slate-500">{{ $booking['guestCount'] ?? '?' }} guest(s)</span>
                            </td>
                            <td class="px-6 py-5 text-slate-300 text-xs font-mono">
                                @if(!empty($booking['quotedPrice']))
                                    {{ $booking['currency'] ?? 'LKR' }} {{ number_format($booking['quotedPrice'], 2) }}
                                @else
                                    <span class="text-slate-600">Not quoted</span>
                                @endif
                            </td>
                            <td class="px-6 py-5">
                                @php $st = $booking['status'] ?? 'pending'; @endphp
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-md border
                                    {{ str_starts_with($st, 'cancelled') || $st === 'declined' || $st === 'expired' ? 'bg-red-500/10 text-red-400 border-red-500/20' : ($st === 'completed' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-amber-500/10 text-amber-400 border-amber-500/20') }}">
                                    {{ ucfirst(str_replace('_', ' ', $st)) }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-right">
                                <a href="{{ route('admin.bookings.show', $booking['id']) }}" class="text-slate-400 hover:text-emerald-400 p-1.5 hover:bg-slate-800 rounded-lg transition" title="View">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-10 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-calendar-xmark text-3xl text-slate-600"></i>
                                    <span>No bookings in this category.</span>
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
