@extends('admin.layout')

@section('content')
<div class="space-y-6">
    <div class="glass-card p-6 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
        <div>
            <h2 class="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
                <i class="fa-solid fa-ban text-amber-500"></i> Rejected Places
            </h2>
            <p class="text-sm text-slate-400">Places that have been rejected and returned to the creator for review.</p>
        </div>
        <div class="flex items-center gap-4 mt-4 md:mt-0 md:ml-auto">
            
        </div>

        <form action="{{ route('admin.places.rejected') }}" method="GET" class="flex flex-wrap items-center gap-3 w-full md:w-auto mt-4 md:mt-0">
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
                <a href="{{ route('admin.places.rejected') }}" class="text-xs text-slate-400 hover:text-white px-2 py-2">
                    <i class="fa-solid fa-xmark"></i> Clear
                </a>
            @endif
        </form>
    </div>

    </form></td></tr>
                    @empty
                    <tr>
                        <td colspan="6" class="py-12 text-center text-slate-500">
                            <i class="fa-solid fa-circle-check text-3xl mb-3 block opacity-40"></i>
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
</div>
@endsection


