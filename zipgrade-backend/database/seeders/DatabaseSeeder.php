<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Classroom;
use App\Models\Student;
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

        // 2. Create Classroom
        $classroom = Classroom::firstOrCreate(
            ['name' => 'Math 101', 'user_id' => $user->id],
            ['section' => 'A']
        );

        // 3. Create Students and attach to Classroom
        $students = Student::factory(5)->create();
        $classroom->students()->attach($students);

        $this->command->info('Classroom "Math 101" created with 5 students.');

        // 4. Run Exam Seeder
        $this->call(ExamSeeder::class);
    }
}
