<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        // Search by name/email
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        // Filter by role
        if ($role = $request->input('role')) {
            $query->where('role', $role);
        }

        // Filter by subscription tier
        if ($tier = $request->input('subscription_tier')) {
            $query->where('subscription_tier', $tier);
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(15);
        return view('admin.users.index', compact('users'));
    }

    public function edit($id)
    {
        $user = User::findOrFail($id);
        return view('admin.users.form', compact('user'));
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $rules = [
            'name' => 'required|string|max:255',
            'role' => 'required|string|in:tourist,guide_approved,banned,admin',
            'subscription_tier' => 'required|string|in:Free,PRO,VIP',
        ];

        // Do not allow the current logged in user to demote themselves from admin or change their own role
        if ($user->id === Auth::id()) {
            unset($rules['role']);
        }

        $data = $request->validate($rules);
        $user->update($data);

        return redirect()->route('admin.users.index')
            ->with('success', "User account for '{$user->name}' updated successfully.");
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);

        if ($user->id === Auth::id()) {
            return back()->withErrors(['error' => 'You cannot delete your own admin account.']);
        }

        $user->delete();

        return redirect()->route('admin.users.index')
            ->with('success', "User '{$user->name}' deleted successfully.");
    }
}
