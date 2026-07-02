@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-user-tie text-emerald-500"></i> Guide Moderation Panel
        </h2>
        <p class="text-sm text-slate-400">Review and moderate tourist guide licenses and enrollment applications.</p>
    </div>

    <!-- Stats & Filters Navigation -->
    <div class="flex flex-col md:flex-row gap-4 items-stretch justify-between">
        <!-- Status Tabs -->
        <div class="bg-slate-900 border border-slate-800 p-1 rounded-xl flex items-center gap-1.5 self-start">
            <a href="{{ route('admin.guides.index', ['status' => 'pending']) }}" class="px-4 py-2 rounded-lg text-xs font-semibold tracking-wide transition {{ $status === 'pending' ? 'bg-amber-500 text-slate-950 font-bold' : 'text-slate-400 hover:text-white' }}">
                Pending ({{ $pendingCount }})
            </a>
            <a href="{{ route('admin.guides.index', ['status' => 'approved']) }}" class="px-4 py-2 rounded-lg text-xs font-semibold tracking-wide transition {{ $status === 'approved' ? 'bg-emerald-500 text-slate-950 font-bold' : 'text-slate-400 hover:text-white' }}">
                Approved ({{ $approvedCount }})
            </a>
            <a href="{{ route('admin.guides.index', ['status' => 'rejected']) }}" class="px-4 py-2 rounded-lg text-xs font-semibold tracking-wide transition {{ $status === 'rejected' ? 'bg-red-500 text-slate-950 font-bold' : 'text-slate-400 hover:text-white' }}">
                Rejected ({{ $rejectedCount }})
            </a>
        </div>

        <!-- Search Form -->
        <form action="{{ route('admin.guides.index') }}" method="GET" class="flex gap-2 w-full md:w-auto">
            <input type="hidden" name="status" value="{{ $status }}">
            <div class="relative flex-1 md:w-72">
                <i class="fa-solid fa-magnifying-glass absolute left-3 top-3 text-slate-500 text-xs"></i>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search guide or license..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2 pl-9 pr-4 text-xs text-white focus:outline-none focus:border-emerald-500/50">
            </div>
            <button type="submit" class="bg-slate-800 hover:bg-slate-750 text-white px-4 py-2 rounded-xl text-xs font-bold border border-slate-700 transition">
                Filter
            </button>
        </form>
    </div>

    <!-- Applications List Table -->
    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">Applicant</th>
                        <th class="px-6 py-4">License Number</th>
                        <th class="px-6 py-4">Category</th>
                        <th class="px-6 py-4">Applied Date</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($applications as $app)
                        <tr class="hover:bg-slate-900/30 transition">
                            <td class="px-6 py-5">
                                <div class="font-bold text-white">{{ $app->user->name ?? 'Unknown User' }}</div>
                                <div class="text-xs text-slate-400 mt-0.5">{{ $app->user->email ?? 'No email' }}</div>
                            </td>
                            <td class="px-6 py-5">
                                <span class="font-mono text-xs text-slate-300 bg-slate-900 border border-slate-800/80 px-2 py-1 rounded">
                                    {{ $app->license_number }}
                                </span>
                            </td>
                            <td class="px-6 py-5 text-slate-300">
                                {{ ucfirst(str_replace('_', ' ', $app->category)) }}
                            </td>
                            <td class="px-6 py-5 text-slate-400 text-xs">
                                {{ $app->applied_at ? $app->applied_at->format('M d, Y h:i A') : $app->created_at->format('M d, Y h:i A') }}
                            </td>
                            <td class="px-6 py-5 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <a href="{{ route('admin.guides.show', $app->id) }}" class="bg-slate-800 hover:bg-slate-750 text-white px-3 py-1.5 rounded-lg text-xs font-bold border border-slate-700 transition flex items-center gap-1.5">
                                        <i class="fa-solid fa-eye text-emerald-400"></i> View Details
                                    </a>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-6 py-12 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-folder-open text-3xl text-slate-600"></i>
                                    <span>No applications found in this section.</span>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($applications->hasPages())
            <div class="px-6 py-4 border-t border-slate-800/40 bg-slate-900/10">
                {{ $applications->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
