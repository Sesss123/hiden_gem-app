@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <i class="fa-solid fa-shield-halved text-red-400"></i> Safety Reports
        </h2>
        <p class="text-sm text-slate-400">Review user/content abuse and AI-output reports.</p>
    </div>

    <div class="flex flex-wrap gap-2">
        @foreach(['pending' => 'Pending', 'resolved' => 'Resolved', 'dismissed' => 'Dismissed', 'all' => 'All'] as $key => $label)
            <a href="{{ route('admin.safety-reports.index', ['status' => $key]) }}"
               class="px-4 py-2 rounded-xl text-sm font-semibold transition {{ $status === $key ? 'bg-red-500/20 text-red-300 border border-red-500/40' : 'bg-slate-900 text-slate-400 border border-slate-800 hover:text-white' }}">
                {{ $label }}
            </a>
        @endforeach
    </div>

    <div class="glass-card rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 uppercase font-semibold">
                        <th class="px-6 py-4">Type</th>
                        <th class="px-6 py-4">Report</th>
                        <th class="px-6 py-4">Reporter / Target</th>
                        <th class="px-6 py-4">Filed</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4 text-right">Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40 text-sm">
                    @forelse($reports as $report)
                        @php $reportType = $report['collection'] === 'ai_output_reports' ? 'ai' : 'abuse'; @endphp
                        <tr class="hover:bg-slate-900/30 transition align-top">
                            <td class="px-6 py-5 text-slate-300">{{ $report['typeLabel'] }}</td>
                            <td class="px-6 py-5 max-w-md">
                                <div class="text-white font-semibold">{{ ucfirst(str_replace('_', ' ', $report['reason'] ?? 'Other')) }}</div>
                                <div class="text-slate-400 mt-1">{{ \Illuminate\Support\Str::limit($report['details'] ?? $report['outputPreview'] ?? '', 180) }}</div>
                                <div class="text-xs text-slate-500 mt-2">{{ $report['targetType'] ?? $report['feature'] ?? 'content' }} · {{ $report['targetId'] ?? $report['outputId'] ?? 'N/A' }}</div>
                            </td>
                            <td class="px-6 py-5 text-slate-400 text-xs font-mono">
                                <div>{{ \Illuminate\Support\Str::limit($report['reportedBy'] ?? 'N/A', 20) }}</div>
                                <div>{{ \Illuminate\Support\Str::limit($report['reportedUserId'] ?? 'AI output', 20) }}</div>
                            </td>
                            <td class="px-6 py-5 text-slate-400 text-xs">{{ \Illuminate\Support\Str::of($report['createdAt'] ?? '')->limit(19, '') }}</td>
                            <td class="px-6 py-5 text-slate-300">{{ ucfirst($report['status'] ?? 'pending') }}</td>
                            <td class="px-6 py-5 text-right">
                                @if(($report['status'] ?? 'pending') === 'pending')
                                    <form action="{{ route('admin.safety-reports.update', [$reportType, $report['id']]) }}" method="POST" class="flex justify-end gap-2">
                                        @csrf
                                        <input name="resolution_note" maxlength="500" placeholder="Optional note" class="w-40 bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-xs text-white">
                                        <button name="status" value="resolved" class="bg-emerald-600 hover:bg-emerald-500 text-white px-3 py-2 rounded-lg text-xs font-semibold">Resolve</button>
                                        <button name="status" value="dismissed" class="bg-slate-700 hover:bg-slate-600 text-white px-3 py-2 rounded-lg text-xs font-semibold">Dismiss</button>
                                    </form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="px-6 py-10 text-center text-slate-500">No safety reports in this category.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
