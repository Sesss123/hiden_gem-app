@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div class="glass-card p-6 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-hourglass-half text-amber-500"></i> Pending Places
            </h2>
            <p class="text-sm text-slate-400">Places submitted by content managers, awaiting your approval before they go live to app users.</p>
        </div>
        <div class="flex items-center gap-4 mt-4 md:mt-0 md:ml-auto">
            <form action="{{ route('admin.places.import') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <input type="file" name="json_file" accept=".json,.jsonl,.txt" class="hidden" id="json_import_file" onchange="if(confirm('Import places from this file?')) this.form.submit();">
                <button type="button" onclick="document.getElementById('json_import_file').click()" class="bg-slate-800 hover:bg-slate-700 text-slate-200 px-4 py-2 rounded-xl text-sm font-bold transition border border-emerald-500/30 flex items-center gap-2 shadow-[0_0_15px_rgba(16,185,129,0.1)] hover:shadow-[0_0_20px_rgba(16,185,129,0.2)]">
                    <i class="fa-solid fa-file-import text-emerald-400"></i> Import JSON
                </button>
            </form>
        </div>

        <form action="{{ route('admin.places.pending') }}" method="GET" class="flex flex-wrap items-center gap-3 w-full md:w-auto mt-4 md:mt-0">
            <div class="relative flex-1 md:w-64">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                    <i class="fa-solid fa-magnifying-glass text-xs"></i>
                </span>
                <input type="text" name="search" value="{{ $search ?? '' }}" placeholder="Search gems, districts..."
                    class="w-full pl-9 pr-4 py-2 bg-slate-900/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
            </div>

            <select name="category" onchange="this.form.submit()" class="bg-slate-900/80 border border-slate-700 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-emerald-500">
                <option value="">All Categories</option>
                @foreach(\App\Models\Place::select('category')->distinct()->orderBy('category')->pluck('category') as $cat)
                    @if($cat)
                        <option value="{{ $cat }}" {{ (isset($category) && $category == $cat) ? 'selected' : '' }}>{{ $cat }}</option>
                    @endif
                @endforeach
            </select>

            @if(!empty($search) || !empty($category))
                <a href="{{ route('admin.places.pending') }}" class="text-xs text-slate-400 hover:text-white px-2 py-2">
                    <i class="fa-solid fa-xmark"></i> Clear
                </a>
            @endif
        </form>
    </div>

    @if(session('duplicate_file_warning'))
    <div class="glass-card p-5 rounded-2xl border border-amber-500/30 bg-amber-500/10 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-300 flex items-center justify-center shrink-0">
                <i class="fa-solid fa-triangle-exclamation text-base"></i>
            </div>
            <div>
                <h4 class="text-sm font-bold text-amber-300">Duplicate Dataset Detected</h4>
                <p class="text-xs text-amber-300/80 mt-0.5">{{ session('duplicate_file_warning')['message'] }}</p>
            </div>
        </div>
        <form action="{{ route('admin.places.import') }}" method="POST" enctype="multipart/form-data">
            @csrf
            <input type="hidden" name="force_reimport" value="1">
            <input type="file" name="json_file" id="force_json_file" class="hidden" onchange="this.form.submit()">
            <button type="button" onclick="document.getElementById('force_json_file').click()" class="bg-amber-600 hover:bg-amber-500 text-slate-950 font-bold px-4 py-2 rounded-xl text-xs transition flex items-center gap-1.5 shadow">
                <i class="fa-solid fa-file-import"></i> Force Re-Import File
            </button>
        </form>
    </div>
    @endif

    @if(isset($datasetImports) && $datasetImports->count() > 0)
    <div class="glass-card p-5 rounded-2xl border border-slate-800 shadow-xl mb-6">
        <div class="flex items-center justify-between mb-3">
            <h3 class="text-sm font-bold text-white flex items-center gap-2">
                <i class="fa-solid fa-clock-rotate-left text-blue-400"></i> Recent JSON Imports & Audit Trail
            </h3>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-left text-xs">
                <thead>
                    <tr class="text-slate-500 border-b border-slate-800/50">
                        <th class="py-2.5 px-3 font-medium">Filename & Hash</th>
                        <th class="py-2.5 px-3 font-medium">Record Breakdown</th>
                        <th class="py-2.5 px-3 font-medium">Uploaded By</th>
                        <th class="py-2.5 px-3 font-medium text-right">Date (SLST)</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/30">
                    @foreach($datasetImports as $import)
                    <tr class="hover:bg-slate-800/20">
                        <td class="py-2.5 px-3">
                            <div class="font-mono text-emerald-400 font-semibold">{{ $import->filename }}</div>
                            @if(!empty($import->file_hash))
                                <div class="text-[10px] text-slate-500 font-mono" title="SHA-256: {{ $import->file_hash }}">
                                    SHA: {{ substr($import->file_hash, 0, 10) }}...{{ substr($import->file_hash, -6) }}
                                </div>
                            @endif
                        </td>
                        <td class="py-2.5 px-3 text-slate-300">
                            <div class="flex items-center gap-1.5 flex-wrap">
                                <span class="inline-block px-2 py-0.5 rounded bg-slate-800 text-[10px] font-medium border border-slate-700">
                                    {{ $import->record_count }} total
                                </span>
                                @if(isset($import->imported_count) && $import->imported_count > 0)
                                    <span class="inline-block px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-300 border border-emerald-500/20 text-[10px]">
                                        +{{ $import->imported_count }} new
                                    </span>
                                @endif
                                @if(isset($import->updated_count) && $import->updated_count > 0)
                                    <span class="inline-block px-2 py-0.5 rounded bg-sky-500/10 text-sky-300 border border-sky-500/20 text-[10px]">
                                        {{ $import->updated_count }} updated
                                    </span>
                                @endif
                                @if(isset($import->duplicate_count) && $import->duplicate_count > 0)
                                    <span class="inline-block px-2 py-0.5 rounded bg-red-500/10 text-red-300 border border-red-500/20 text-[10px]">{{ $import->duplicate_count }} duplicate rows</span>
                                @endif
                                @if(isset($import->skipped_count) && $import->skipped_count > 0)
                                    <span class="inline-block px-2 py-0.5 rounded bg-slate-800 text-slate-400 text-[10px]">
                                        {{ $import->skipped_count }} skipped
                                    </span>
                                @endif
                            </div>
                        </td>
                        <td class="py-2.5 px-3 text-slate-400">{{ $import->user ? $import->user->name : 'System' }}</td>
                        <td class="py-2.5 px-3 text-slate-400 text-right font-mono">{{ optional($import->created_at)->format('M d, Y · h:i A') ?? 'N/A' }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
    @endif

    <!-- Bulk Approval Form (Submits selected checkbox IDs) -->
    <form id="bulk-approve-form" action="{{ route('admin.places.bulk_approve') }}" method="POST" onsubmit="return confirm('Approve all selected places and publish them live?');">
        @csrf
        <div id="bulk-inputs-container"></div>
    </form>

    <!-- Desktop Table View (Hidden on mobile <768px) -->
    <div class="hidden md:block glass-card rounded-2xl overflow-hidden border border-slate-800 shadow-xl relative">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/60 text-slate-400 text-xs font-semibold uppercase tracking-wider border-b border-slate-800">
                        <th class="py-4 px-4 w-10 text-center">
                            <input type="checkbox" id="select-all-pending" class="rounded border-slate-700 bg-slate-900 text-emerald-500 focus:ring-emerald-500 cursor-pointer" title="Select All">
                        </th>
                        <th class="py-4 px-4">Gem Name & ID</th>
                        <th class="py-4 px-4">Location</th>
                        <th class="py-4 px-4">Category</th>
                        <th class="py-4 px-4">Origin / Source</th>
                        <th class="py-4 px-4">Submitted By</th>
                        <th class="py-4 px-4">Date</th>
                        <th class="py-4 px-6 text-right sticky right-0 bg-slate-900/90 backdrop-blur">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-sm">
                    @forelse($places as $place)
                    <tr class="hover:bg-slate-800/40 transition duration-150">
                        <td class="py-3 px-4 text-center">
                            <input type="checkbox" value="{{ $place->id }}" class="pending-place-checkbox rounded border-slate-700 bg-slate-900 text-emerald-500 focus:ring-emerald-500 cursor-pointer" onchange="updateBulkBar()">
                        </td>
                        <td class="py-3 px-4 font-medium text-white">
                            <div class="font-bold flex items-center gap-1.5">{{ $place->name }}</div>
                            <div class="text-xs text-slate-500 font-mono mt-0.5">{{ $place->id }}</div>
                        </td>
                        <td class="py-3 px-4 text-slate-300">
                            <span class="inline-flex items-center gap-1 bg-slate-900 px-2.5 py-1 rounded-lg text-xs text-slate-300 border border-slate-800">
                                <i class="fa-solid fa-location-dot text-teal-400 text-[10px]"></i> {{ $place->district }}
                            </span>
                        </td>
                        <td class="py-3 px-4">
                            <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                {{ $place->category }}
                            </span>
                        </td>
                        <td class="py-3 px-4">
                            @if(empty($place->created_by))
                                <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                                    <i class="fa-solid fa-file-import text-[10px]"></i> JSON Import
                                </span>
                            @else
                                <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-teal-500/10 text-teal-300 border border-teal-500/20">
                                    <i class="fa-solid fa-user-pen text-[10px]"></i> CMS Admin
                                </span>
                            @endif
                        </td>
                        <td class="py-3 px-4 text-slate-300 text-xs">
                            @if($place->creator)
                                <span class="inline-flex items-center gap-1.5">
                                    <i class="fa-solid fa-user-pen text-slate-500"></i> {{ $place->creator->name }}
                                </span>
                            @else
                                <span class="text-slate-600 italic">Unclaimed</span>
                            @endif
                        </td>
                        <td class="py-3 px-4 text-slate-400 font-mono text-xs">
                            {{ $place->created_at ? $place->created_at->diffForHumans() : 'N/A' }}
                        </td>
                        <td class="py-3 px-6 text-right sticky right-0 bg-slate-900/90 backdrop-blur">
                            <div class="flex items-center justify-end gap-1.5">
                                <a href="{{ route('admin.places.edit', $place->id) }}" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition shadow" title="Review Details">
                                    <i class="fa-solid fa-eye text-xs"></i>
                                </a>
                                <form action="{{ route('admin.places.approve', $place->id) }}" method="POST" class="inline-block" onsubmit="return confirm('Approve {{ $place->name }}? It will immediately become visible to app users.')">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-emerald-600 text-slate-300 hover:text-white transition shadow" title="Approve and Publish">
                                        <i class="fa-solid fa-check text-xs"></i>
                                    </button>
                                </form>
                                <button type="button" onclick="document.getElementById('reject-modal-{{ $place->id }}').classList.remove('hidden')"
                                    class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800 hover:bg-red-600 text-slate-300 hover:text-white transition shadow" title="Reject Place">
                                    <i class="fa-solid fa-xmark text-xs"></i>
                                </button>
                            </div>
                        </td>
                    </tr>

                    <!-- Reject reason row -->
                    <tr id="reject-modal-{{ $place->id }}" class="hidden">
                        <td colspan="8" class="px-6 py-4 bg-slate-900/50">
                            <form action="{{ route('admin.places.reject', $place->id) }}" method="POST" class="flex items-center gap-3">
                                @csrf
                                <input type="text" name="review_reason" required maxlength="1000" placeholder="Reason for rejecting this place..."
                                    class="flex-1 bg-slate-950 border border-slate-800 rounded-xl py-2 px-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-red-500/50 transition">
                                <button type="submit" class="bg-red-600 hover:bg-red-500 text-white px-4 py-2 rounded-xl text-xs font-semibold transition">
                                    Confirm Reject
                                </button>
                                <button type="button" onclick="document.getElementById('reject-modal-{{ $place->id }}').classList.add('hidden')"
                                    class="text-slate-400 text-xs px-2">Cancel</button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="8" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-circle-check text-3xl mb-3 block opacity-40 text-emerald-500"></i>
                            No places awaiting review. All caught up.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($places->hasPages())
            <div class="p-4 border-t border-slate-800 bg-slate-900/40">
                {{ $places->links() }}
            </div>
        @endif
    </div>

    <!-- Mobile Cards View (<768px) -->
    <div class="md:hidden space-y-4">
        @forelse($places as $place)
        <div class="glass-card p-4 rounded-2xl border border-slate-800 space-y-3">
            <div class="flex items-start justify-between gap-2">
                <div>
                    <h3 class="font-bold text-white text-base">{{ $place->name }}</h3>
                    <div class="text-[11px] text-slate-500 font-mono">{{ $place->id }}</div>
                </div>
                <span class="inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    Pending
                </span>
            </div>

            <div class="flex flex-wrap gap-2 text-xs">
                <span class="bg-slate-900 px-2.5 py-1 rounded-lg text-slate-300 border border-slate-800 flex items-center gap-1">
                    <i class="fa-solid fa-location-dot text-teal-400 text-[10px]"></i> {{ $place->district }}
                </span>
                <span class="bg-slate-900 px-2.5 py-1 rounded-lg text-slate-300 border border-slate-800">
                    {{ $place->category }}
                </span>
                @if(empty($place->created_by))
                    <span class="bg-indigo-500/10 text-indigo-300 px-2 py-0.5 rounded border border-indigo-500/20 text-[10px]">JSON Import</span>
                @else
                    <span class="bg-teal-500/10 text-teal-300 px-2 py-0.5 rounded border border-teal-500/20 text-[10px]">CMS Admin</span>
                @endif
            </div>

            <div class="text-[11px] text-slate-500 flex items-center justify-between border-t border-slate-800/60 pt-2">
                <span>By {{ $place->creator ? $place->creator->name : 'Unclaimed' }}</span>
                <span>{{ optional($place->created_at)->diffForHumans() }}</span>
            </div>

            <div class="grid grid-cols-3 gap-2 pt-1 border-t border-slate-800">
                <a href="{{ route('admin.places.edit', $place->id) }}" class="py-2 text-center rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200">
                    <i class="fa-solid fa-pen-to-square mr-1"></i> Edit
                </a>
                <button type="button" onclick="document.getElementById('mobile-reject-{{ $place->id }}').classList.toggle('hidden')" class="py-2 text-center rounded-xl bg-red-500/20 hover:bg-red-500/30 text-xs font-semibold text-red-300 border border-red-500/30">
                    <i class="fa-solid fa-xmark mr-1"></i> Reject
                </button>
                <form action="{{ route('admin.places.approve', $place->id) }}" method="POST" onsubmit="return confirm('Approve {{ $place->name }}?')">
                    @csrf
                    <button type="submit" class="w-full py-2 text-center rounded-xl bg-emerald-500/20 hover:bg-emerald-500/30 text-xs font-semibold text-emerald-300 border border-emerald-500/30">
                        <i class="fa-solid fa-check mr-1"></i> Approve
                    </button>
                </form>
            </div>

            <div id="mobile-reject-{{ $place->id }}" class="hidden pt-2 border-t border-slate-800">
                <form action="{{ route('admin.places.reject', $place->id) }}" method="POST" class="space-y-2">
                    @csrf
                    <input type="text" name="review_reason" required maxlength="1000" placeholder="Reason for rejection..." class="w-full bg-slate-950 border border-slate-800 rounded-xl py-2 px-3 text-xs text-white placeholder-slate-500">
                    <button type="submit" class="w-full bg-red-600 hover:bg-red-500 text-white py-1.5 rounded-xl text-xs font-semibold">Confirm Reject</button>
                </form>
            </div>
        </div>
        @empty
        <div class="glass-card p-8 rounded-2xl border border-slate-800 text-center text-slate-500">
            <i class="fa-solid fa-circle-check text-3xl mb-3 block opacity-40 text-emerald-500"></i>
            No places awaiting review. All caught up.
        </div>
        @endforelse

        @if($places->hasPages())
            <div class="glass-card p-3 rounded-2xl border border-slate-800">
                {{ $places->links() }}
            </div>
        @endif
    </div>

    <!-- Floating Bulk Action Bar -->
    <div id="bulk-action-bar" class="fixed bottom-6 left-1/2 -translate-x-1/2 bg-slate-900/95 border border-emerald-500/40 rounded-2xl px-6 py-3.5 shadow-2xl backdrop-blur flex items-center gap-4 transition-all duration-300 translate-y-24 opacity-0 pointer-events-none z-50">
        <span class="text-xs text-slate-300 font-medium">
            <span id="bulk-count" class="font-bold text-emerald-400">0</span> places selected
        </span>
        <button type="button" onclick="submitBulkApprove()" class="bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 shadow-lg shadow-emerald-600/20">
            <i class="fa-solid fa-check-double"></i> Approve Selected
        </button>
        <button type="button" onclick="clearBulkSelection()" class="text-xs text-slate-400 hover:text-white px-2 py-1 transition">
            Deselect
        </button>
    </div>
</div>

<script>
    const selectAllBtn = document.getElementById('select-all-pending');
    const bulkBar = document.getElementById('bulk-action-bar');
    const bulkCountSpan = document.getElementById('bulk-count');
    const bulkInputsContainer = document.getElementById('bulk-inputs-container');

    if (selectAllBtn) {
        selectAllBtn.addEventListener('change', function() {
            const checkboxes = document.querySelectorAll('.pending-place-checkbox');
            checkboxes.forEach(cb => cb.checked = selectAllBtn.checked);
            updateBulkBar();
        });
    }

    function updateBulkBar() {
        const checkedBoxes = document.querySelectorAll('.pending-place-checkbox:checked');
        const count = checkedBoxes.length;

        if (bulkCountSpan) bulkCountSpan.textContent = count;

        if (count > 0) {
            bulkBar.classList.remove('translate-y-24', 'opacity-0', 'pointer-events-none');
        } else {
            bulkBar.classList.add('translate-y-24', 'opacity-0', 'pointer-events-none');
            if (selectAllBtn) selectAllBtn.checked = false;
        }
    }

    function clearBulkSelection() {
        document.querySelectorAll('.pending-place-checkbox').forEach(cb => cb.checked = false);
        if (selectAllBtn) selectAllBtn.checked = false;
        updateBulkBar();
    }

    function submitBulkApprove() {
        const checkedBoxes = document.querySelectorAll('.pending-place-checkbox:checked');
        if (checkedBoxes.length === 0) return;

        bulkInputsContainer.innerHTML = '';
        checkedBoxes.forEach(cb => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'ids[]';
            input.value = cb.value;
            bulkInputsContainer.appendChild(input);
        });

        document.getElementById('bulk-approve-form').submit();
    }
</script>
@endsection
