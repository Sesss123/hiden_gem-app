<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rules\Password;

class UserController extends Controller
{
    use LogsAdminActivity;

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

    public function create()
    {
        return view('admin.users.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => ['required', 'string', Password::min(8)->mixedCase()->numbers()],
            'role' => ['required', 'string', \Illuminate\Validation\Rule::in(User::allRoles())],
        ]);

        $data['password'] = bcrypt($data['password']);

        // is_admin is intentionally NOT mass-assignable (see BUG-C01 Fix in
        // User::$fillable) so it can never be set via a crafted request —
        // it must be stamped explicitly after create() instead. Derived from
        // role (not hardcoded true) so a crafted request with role=tourist/
        // banned — both valid per Rule::in(User::allRoles()) above even
        // though this form's own dropdown only offers content_manager/admin/
        // super_admin — can't grant panel access to a non-admin role.
        $user = User::create($data);
        $user->is_admin = $user->isFullAdmin() || $user->isContentManager();
        $user->save();

        $this->logAdminAction('user.created', 'User', $user->id, ['role' => $user->role, 'email' => $user->email]);

        return redirect()->route('admin.users.index')
            ->with('success', "Admin account for '{$user->name}' created successfully.");
    }

    public function edit($id)
    {
        $user = User::findOrFail($id);
        return view('admin.users.form', compact('user'));
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $roleFrom = $user->role;

        $rules = [
            'name' => 'required|string|max:255',
            'role' => ['required', 'string', \Illuminate\Validation\Rule::in(User::allRoles())],
            'subscription_tier' => 'required|string|in:Free,PRO,VIP',
            'password' => ['nullable', 'string', Password::min(8)->mixedCase()->numbers()],
        ];

        // Do not allow the current logged in user to demote themselves from admin or change their own role
        if ($user->id === Auth::id()) {
            unset($rules['role']);
        }

        $data = $request->validate($rules);

        // Leave-blank-to-keep-current-password: only touch the column if a
        // new value was actually submitted, otherwise update() would null it out.
        if (!empty($data['password'])) {
            $data['password'] = bcrypt($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);

        // is_admin isn't mass-assignable (see store()) and must stay in sync
        // with role: promoting someone to content_manager/admin/super_admin
        // here should actually grant them panel access, and demoting them
        // away from those roles should revoke it. Skipped when role wasn't
        // part of this request (self-edit unsets 'role' above).
        if (array_key_exists('role', $data)) {
            $user->is_admin = $user->isFullAdmin() || $user->isContentManager();
            $user->save();
        }

        $this->logAdminAction('user.updated', 'User', $user->id, ['role_from' => $roleFrom, 'role_to' => $user->role]);

        return redirect()->route('admin.users.index')
            ->with('success', "User account for '{$user->name}' updated successfully.");
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);

        if ($user->id === Auth::id()) {
            return back()->withErrors(['error' => 'You cannot delete your own admin account.']);
        }

        $userName = $user->name;
        $userEmail = $user->email;
        $user->delete();

        $this->logAdminAction('user.deleted', 'User', $id, ['name' => $userName, 'email' => $userEmail]);

        return redirect()->route('admin.users.index')
            ->with('success', "User '{$userName}' deleted successfully.");
    }
}
