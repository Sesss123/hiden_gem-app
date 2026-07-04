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
        // Seed Places (Fix BUG-R16)
        $this->call(PlaceSeeder::class);

        // Admin user (if not exists)
        $admin = \App\Models\User::firstOrCreate(
            ['email' => 'admin@hiddengemssl.com'],
            [
                'name' => 'Genesis Super Admin',
                'password' => bcrypt('password123'),
                'is_admin' => true,
                'role' => 'super_admin',
            ]
        );
        if ($admin && ($admin->role !== 'super_admin' || !$admin->is_admin)) {
            $admin->update(['role' => 'super_admin', 'is_admin' => true]);
        }

        // Seed Events
        \App\Models\Event::firstOrCreate(
            ['name' => 'Sinhala & Tamil New Year'],
            [
                'description' => 'Sri Lankan traditional new year celebrations with local games and rituals.',
                'category' => 'cultural',
                'location' => 'Island-wide',
                'date' => '04-13',
                'is_active' => true,
            ]
        );

        \App\Models\Event::firstOrCreate(
            ['name' => 'Kandy Esala Perahera'],
            [
                'description' => 'Historic festival featuring grand processions, traditional dancers, and elephants.',
                'category' => 'religious',
                'location' => 'Kandy',
                'start' => '07-01',
                'end' => '08-31',
                'is_active' => true,
            ]
        );

        \App\Models\Event::firstOrCreate(
            ['name' => 'Vesak Festival'],
            [
                'description' => 'Buddhist festival of lights commemorating birth, enlightenment, and passing of Buddha.',
                'category' => 'religious',
                'location' => 'Colombo',
                'date' => '05-05',
                'is_active' => true,
            ]
        );

        // Seed Guide Users & Applications
        $guide1 = \App\Models\User::firstOrCreate(
            ['email' => 'amara@example.com'],
            [
                'name' => 'Amara Perera',
                'password' => bcrypt('password123'),
                'is_admin' => false,
                'role' => 'tourist',
            ]
        );

        \App\Models\GuideApplication::firstOrCreate(
            ['user_id' => $guide1->id],
            [
                'license_number' => 'LG-2026-904',
                'bio' => 'Licensed tourist guide with 5 years experience specializing in Sigiriya and cultural triangle tours.',
                'category' => 'cultural_tours',
                'license_doc_url' => 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&q=80',
                'nic_doc_url' => 'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=600&q=80',
                'selfie_doc_url' => 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
                'status' => 'pending',
            ]
        );

        $guide2 = \App\Models\User::firstOrCreate(
            ['email' => 'nihal@example.com'],
            [
                'name' => 'Nihal Silva',
                'password' => bcrypt('password123'),
                'is_admin' => false,
                'role' => 'guide_approved',
            ]
        );

        \App\Models\GuideApplication::firstOrCreate(
            ['user_id' => $guide2->id],
            [
                'license_number' => 'LG-2025-103',
                'bio' => 'Adventure guide focusing on hiking, bird watching, and wildlife safaris in Ella and Yala.',
                'category' => 'wildlife_hiking',
                'license_doc_url' => 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&q=80',
                'nic_doc_url' => 'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=600&q=80',
                'selfie_doc_url' => 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=200&q=80',
                'status' => 'approved',
            ]
        );

        $guide3 = \App\Models\User::firstOrCreate(
            ['email' => 'kusal@example.com'],
            [
                'name' => 'Kusal Mendis',
                'password' => bcrypt('password123'),
                'is_admin' => false,
                'role' => 'tourist',
            ]
        );

        \App\Models\GuideApplication::firstOrCreate(
            ['user_id' => $guide3->id],
            [
                'license_number' => 'LG-2026-788',
                'bio' => 'Local food explorer offering culinary excursions in Galle and Colombo night markets.',
                'category' => 'culinary_tours',
                'license_doc_url' => 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&q=80',
                'nic_doc_url' => 'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=600&q=80',
                'selfie_doc_url' => 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
                'status' => 'rejected',
            ]
        );
    }
}
