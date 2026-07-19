@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-users text-emerald-500"></i> User & Premium Subscription Management
            </h2>
            <p class="text-sm text-slate-400">List all registered tourist/guide accounts, assign roles, and manage PRO/VIP subscriptions.</p>
        </div>
        <div>
            <a href="{{ route('admin.users.create') }}" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-4 py-2 rounded-xl text-sm font-semibold shadow-md shadow-emerald-950/20 transition duration-200 flex items-center gap-2 glow-effect">
                <i class="fa-solid fa-user-plus"></i> New Admin User
            </a>
        </div>
    </div>

    <!-- Filters & Search -->
    <div class="glass-card p-4 rounded-2xl">
        <form action="{{ route('admin.users.index') }}" method="GET" class="flex flex-col md:flex-row gap-4 items-center justify-between">
            <!-- Search field -->
            <div class="relative w-full md:flex-1">
                <i class="fa-solid fa-magnifying-glass absolute left-4 top-3.5 text-slate-500 text-sm"></i>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search users by name or email..." class="w-full bg-slate-900 border border-slate-800 rounded-xl py-2.5 pl-11 pr-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50">
            </div>

            <div class="flex flex-wrap gap-3 w-full md:w-auto">
                <!-- Role Filter -->
                <select name="role" class="bg-slate-900 border border-slate-800 rounded-xl py-2.5 px-4 text-sm text-white focus:outline-none focus:border-emerald-500/50">
                    <option value="">All Roles</option>
                    <option value="tourist" {{ request('role') == 'tourist' ? 'selected' : '' }}>Tourist</option>
                    <option value="guide_approved" {{ request('role') == 'guide_approved' ? 'selected' : '' }}>Approved Guide</option>
                    <option value="admin" {{ request('role') == 'admin' ? 'selected' : '' }}>Admin</option>
                    <option value="banned" {{ request('role') == 'banned' ? 'selected' : '' }}>Banned</option>
                </select>

                <!-- Subscription Filter -->
                <select name="subscription_tier" class="bg-slate-900 border border-slate-800 rounded-xl py-2.5 px-4 text-sm text-white focus:outline-none focus:border-emerald-500/50">
                    <option value="">All Tiers</option>
                    <option value="Free" {{ request('subscription_tier') == 'Free' ? 'selected' : '' }}>Free</option>
                    <option value="PRO" {{ request('subscription_tier') == 'PRO' ? 'selected' : '' }}>PRO</option>
                    <option value="VIP" {{ request('subscription_tier') == 'VIP' ? 'selected' : '' }}>VIP</option>
                </select>

                <button type="submit" class="bg-slate-800 hover:bg-slate-750 text-white px-5 py-2.5 rounded-xl text-sm font-bold border border-slate-700 transition">
                    Filter
                </button>

                @if(request('search') || request('role') || request('subscription_tier'))
                    <a href="{{ route('admin.users.index') }}" class="bg-slate-900 hover:bg-slate-850 text-slate-400 border border-slate-800 px-5 py-2.5 rounded-xl text-sm font-bold transition flex items-center justify-center">
                        Clear
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Users Table -->
    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">User Details</th>
                        <th class="px-6 py-4">Role</th>
                        <th class="px-6 py-4">Subscription</th>
                        <th class="px-6 py-4">Member Since</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($users as $u)
                        <tr class="hover:bg-slate-900/30 transition">
                            <!-- Details -->
                            <td class="px-6 py-5">
                                <div class="font-bold text-white flex items-center gap-2">
                                    {{ $u->name }}
                                    @if(auth()->id() === $u->id)
                                        <span class="bg-slate-900 text-slate-400 text-[10px] px-2 py-0.5 rounded border border-slate-800 font-semibold font-mono">YOU</span>
                                    @endif
                                </div>
                                <div class="text-xs text-slate-400 mt-0.5">{{ $u->email }}</div>
                            </td>

                            <!-- Role -->
                            <td class="px-6 py-5">
                                @if($u->role === 'admin')
                                    <span class="bg-indigo-500/10 text-indigo-400 text-xs px-2.5 py-1 rounded-full font-bold border border-indigo-500/20">
                                        <i class="fa-solid fa-user-shield text-[10px] mr-1"></i> Admin
                                    </span>
                                @elseif($u->role === 'guide_approved')
                                    <span class="bg-emerald-500/10 text-emerald-400 text-xs px-2.5 py-1 rounded-full font-bold border border-emerald-500/20">
                                        <i class="fa-solid fa-user-tie text-[10px] mr-1"></i> Guide
                                    </span>
                                @elseif($u->role === 'banned')
                                    <span class="bg-red-500/10 text-red-400 text-xs px-2.5 py-1 rounded-full font-bold border border-red-500/20 uppercase tracking-wider">
                                        <i class="fa-solid fa-ban text-[10px] mr-1"></i> Banned
                                    </span>
                                @elseif($u->role === 'content_manager')
                                    <span class="bg-amber-500/10 text-amber-400 text-xs px-2.5 py-1 rounded-full font-bold border border-amber-500/20">
                                        <i class="fa-solid fa-pen-nib text-[10px] mr-1"></i> Content Manager
                                    </span>
                                @else
                                    <span class="bg-slate-800 text-slate-300 text-xs px-2.5 py-1 rounded-full border border-slate-700 font-medium">
                                        Tourist
                                    </span>
                                @endif
                            </td>

                            <!-- Subscription Tier -->
                            <td class="px-6 py-5">
                                @if($u->subscription_tier === 'VIP')
                                    <span class="bg-gradient-to-r from-amber-500 to-yellow-400 text-slate-950 text-xs px-3 py-1 rounded-full font-black shadow-sm tracking-wide">
                                        VIP GOLD
                                    </span>
                                @elseif($u->subscription_tier === 'PRO')
                                    <span class="bg-gradient-to-r from-cyan-600 to-teal-500 text-white text-xs px-3 py-1 rounded-full font-bold shadow-sm tracking-wide">
                                        PRO MEMBER
                                    </span>
                                @else
                                    <span class="text-slate-400 text-xs font-semibold bg-slate-900 border border-slate-850 px-2.5 py-1 rounded-full">
                                        Free Tier
                                    </span>
                                @endif
                            </td>

                            <!-- Registered -->
                            <td class="px-6 py-5 text-slate-450 text-xs">
                                {{ $u->created_at ? $u->created_at->format('M d, Y') : 'N/A' }}
                            </td>

                            <!-- Actions -->
                            <td class="px-6 py-5 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <a href="{{ route('admin.users.edit', $u->id) }}" class="text-slate-450 hover:text-emerald-455 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Modify Permissions">
                                        <i class="fa-solid fa-user-pen"></i> Edit
                                    </a>
                                    @if(auth()->id() !== $u->id)
                                        <form action="{{ route('admin.users.destroy', $u->id) }}" method="POST" onsubmit="return confirm('Are you sure you want to permanently delete this user account?');" class="inline">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="text-slate-450 hover:text-red-405 p-1.5 hover:bg-slate-800 rounded-lg transition" title="Delete Profile">
                                                <i class="fa-solid fa-user-xmark"></i>
                                            </button>
                                        </form>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-6 py-12 text-center text-slate-500">
                                <div class="flex flex-col items-center justify-center gap-2">
                                    <i class="fa-solid fa-users-slash text-3xl text-slate-600"></i>
                                    <span>No accounts matching standard criteria found.</span>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($users->hasPages())
            <div class="px-6 py-4 border-t border-slate-800/40 bg-slate-900/10">
                {{ $users->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
