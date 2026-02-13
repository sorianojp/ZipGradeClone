<?php

namespace Database\Seeders;

use App\Models\User;

use App\Models\Exam;
use App\Models\Question;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Create or Get Test User
        $user = User::firstOrCreate(
            ['email' => 'teacher@example.com'],
            [
                'name' => 'Test Teacher',
                'password' => Hash::make('password'),
            ]
        );

        $this->command->info('User: teacher@example.com / password');

        // 2. Mock some data if needed, or just leave user only.
        // simplified app has no classrooms/students tables.

        // 4. Run Exam Seeder
        $this->call(ExamSeeder::class);
    }
}
