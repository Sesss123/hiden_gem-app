@extends('admin.layout')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">
    <!-- Header -->
    <div>
        <a href="{{ route('admin.guides.index', ['status' => $application->status]) }}" class="text-sm font-semibold text-emerald-400 hover:text-emerald-300 transition flex items-center gap-1.5 mb-2">
            <i class="fa-solid fa-arrow-left"></i> Back to Applications
        </a>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            Application Details: {{ $application->user->name ?? 'Unknown User' }}
        </h2>
        <p class="text-sm text-slate-400">Review application documents, bio info, and licensing validity.</p>
    </div>

    <!-- Status Banner -->
    <div class="glass-card p-4 rounded-2xl flex items-center justify-between border-slate-800">
        <div class="flex items-center gap-3">
            <span class="text-slate-400 font-medium text-sm">Status:</span>
            @if($application->status === 'pending')
                <span class="bg-amber-500/10 text-amber-400 text-xs px-3 py-1 rounded-full font-bold border border-amber-500/20 uppercase tracking-wide">
                    Pending Admin Review
                </span>
            @elseif($application->status === 'approved')
                <span class="bg-emerald-500/10 text-emerald-400 text-xs px-3 py-1 rounded-full font-bold border border-emerald-500/20 uppercase tracking-wide">
                    Approved Guide
                </span>
            @else
                <span class="bg-red-500/10 text-red-400 text-xs px-3 py-1 rounded-full font-bold border border-red-500/20 uppercase tracking-wide">
                    Rejected
                </span>
            @endif
        </div>
        <div class="text-xs text-slate-500 font-mono">
            Submitted: {{ $application->created_at->format('M d, Y H:i') }}
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Sidebar Profile -->
        <div class="md:col-span-1 space-y-6">
            <div class="glass-card p-6 rounded-3xl text-center">
                <div class="w-24 h-24 mx-auto bg-slate-900 rounded-full border-2 border-slate-800 flex items-center justify-center overflow-hidden mb-4 shadow-inner">
                    @if($application->selfie_doc_url)
                        <img src="{{ $application->selfie_doc_url }}" alt="Selfie" class="w-full h-full object-cover">
                    @else
                        <i class="fa-solid fa-user text-slate-600 text-3xl"></i>
                    @endif
                </div>
                <h3 class="font-bold text-white text-lg">{{ $application->user->name ?? 'Unknown User' }}</h3>
                <p class="text-xs text-slate-400 mt-1 mb-4">{{ $application->user->email ?? 'No email' }}</p>
                <div class="text-xs text-slate-500 bg-slate-900/60 border border-slate-800/80 px-3 py-2 rounded-xl text-left space-y-1.5">
                    <div><span class="text-slate-400">Current Role:</span> <span class="font-bold text-emerald-400">{{ ucfirst($application->user->role ?? 'tourist') }}</span></div>
                    <div><span class="text-slate-400">Subs Tier:</span> <span class="font-semibold text-slate-300">{{ $application->user->subscription_tier ?? 'Free' }}</span></div>
                </div>
            </div>

            <!-- Documents Panel -->
            <div class="glass-card p-6 rounded-3xl space-y-4">
                <h4 class="text-xs font-bold uppercase tracking-wider text-slate-400">Verification Files</h4>
                <div class="space-y-3">
                    @if($application->license_doc_url)
                        <a href="{{ $application->license_doc_url }}" target="_blank" class="flex items-center justify-between p-2 bg-slate-900 rounded-lg hover:bg-slate-850 border border-slate-800 transition">
                            <span class="text-xs text-slate-300"><i class="fa-regular fa-id-card text-emerald-400 mr-2"></i> License Doc</span>
                            <i class="fa-solid fa-up-right-from-square text-xs text-slate-500"></i>
                        </a>
                    @else
                        <div class="text-xs text-slate-650 p-2 bg-slate-900 rounded-lg border border-slate-850"><i class="fa-regular fa-id-card mr-2"></i> License Doc Missing</div>
                    @endif

                    @if($application->nic_doc_url)
                        <a href="{{ $application->nic_doc_url }}" target="_blank" class="flex items-center justify-between p-2 bg-slate-900 rounded-lg hover:bg-slate-850 border border-slate-800 transition">
                            <span class="text-xs text-slate-300"><i class="fa-regular fa-address-card text-emerald-400 mr-2"></i> NIC Doc</span>
                            <i class="fa-solid fa-up-right-from-square text-xs text-slate-500"></i>
                        </a>
                    @else
                        <div class="text-xs text-slate-650 p-2 bg-slate-900 rounded-lg border border-slate-850"><i class="fa-regular fa-address-card mr-2"></i> NIC Doc Missing</div>
                    @endif

                    @if($application->selfie_doc_url)
                        <a href="{{ $application->selfie_doc_url }}" target="_blank" class="flex items-center justify-between p-2 bg-slate-900 rounded-lg hover:bg-slate-850 border border-slate-800 transition">
                            <span class="text-xs text-slate-300"><i class="fa-regular fa-image text-emerald-400 mr-2"></i> Selfie Doc</span>
                            <i class="fa-solid fa-up-right-from-square text-xs text-slate-500"></i>
                        </a>
                    @endif
                </div>
            </div>
        </div>

        <!-- Main Details and Form Info -->
        <div class="md:col-span-2 space-y-6">
            <div class="glass-card p-6 md:p-8 rounded-3xl space-y-6">
                <!-- Info Section -->
                <div class="space-y-4">
                    <h3 class="text-sm font-bold uppercase tracking-wider text-emerald-400">Application Info</h3>
                    <div class="grid grid-cols-2 gap-4 text-sm">
                        <div class="bg-slate-900/50 p-3 rounded-xl border border-slate-800/40">
                            <div class="text-xs text-slate-500">License Number</div>
                            <div class="font-mono font-bold text-white mt-1">{{ $application->license_number }}</div>
                        </div>
                        <div class="bg-slate-900/50 p-3 rounded-xl border border-slate-800/40">
                            <div class="text-xs text-slate-500">Guide Category</div>
                            <div class="font-bold text-white mt-1">{{ ucfirst(str_replace('_', ' ', $application->category)) }}</div>
                        </div>
                    </div>
                </div>

                <!-- Bio -->
                <div class="space-y-2 border-t border-slate-800/60 pt-6">
                    <h3 class="text-sm font-bold uppercase tracking-wider text-emerald-400">Professional Bio</h3>
                    <div class="text-slate-300 bg-slate-900 p-4 rounded-xl border border-slate-800/50 text-sm leading-relaxed whitespace-pre-line">
                        {{ $application->bio ?? 'No bio provided.' }}
                    </div>
                </div>

                <!-- Verification Decisions -->
                <div class="space-y-4 border-t border-slate-800/60 pt-6">
                    <h3 class="text-sm font-bold uppercase tracking-wider text-emerald-400">Administrative Actions</h3>
                    
                    <div class="flex flex-wrap gap-3">
                        @if($application->status === 'pending')
                            <form action="{{ route('admin.guides.approve', $application->id) }}" method="POST" class="inline">
                                @csrf
                                <button type="submit" class="bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white px-5 py-2.5 rounded-xl text-sm font-semibold transition flex items-center gap-1.5 shadow-md shadow-emerald-950/20">
                                    <i class="fa-solid fa-check"></i> Approve Application
                                </button>
                            </form>
                            
                            <form action="{{ route('admin.guides.reject', $application->id) }}" method="POST" class="inline">
                                @csrf
                                <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-white px-5 py-2.5 rounded-xl text-sm font-semibold border border-slate-700 transition flex items-center gap-1.5">
                                    <i class="fa-solid fa-xmark"></i> Reject Application
                                </button>
                            </form>
                        @endif

                        @if($application->status !== 'pending')
                            <form action="{{ route('admin.guides.remove', $application->id) }}" method="POST" onsubmit="return confirm('Are you sure you want to remove this guide application and downgrade user role to tourist?');" class="inline">
                                @csrf
                                <button type="submit" class="bg-slate-800 hover:bg-slate-700 text-slate-300 px-5 py-2.5 rounded-xl text-sm font-semibold border border-slate-750 transition flex items-center gap-1.5">
                                    <i class="fa-solid fa-user-minus"></i> Remove Association
                                </button>
                            </form>
                        @endif

                        @if(($application->user->role ?? '') !== 'banned')
                            <form action="{{ route('admin.guides.ban', $application->id) }}" method="POST" onsubmit="return confirm('Warning! This will block the user from logging into the app. Continue?');" class="inline">
                                @csrf
                                <button type="submit" class="bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/25 px-5 py-2.5 rounded-xl text-sm font-semibold transition flex items-center gap-1.5 ml-auto">
                                    <i class="fa-solid fa-ban"></i> Ban User
                                </button>
                            </form>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
