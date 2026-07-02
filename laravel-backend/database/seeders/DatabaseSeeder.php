<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        \App\Models\User::create([
            'name' => 'Genesis Super Admin',
            'email' => 'admin@hiddengemssl.com',
            'password' => bcrypt('password123'),
            'is_admin' => true,
        ]);
    }
}
