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
        // 1. Create a Test User
        $user = User::factory()->create([
            'name' => 'Test Teacher',
            'email' => 'teacher@example.com',
            'password' => Hash::make('password'),
        ]);

        $this->command->info('User created: teacher@example.com / password');

        // 2. Create a Classroom
        $classroom = Classroom::create([
            'user_id' => $user->id,
            'name' => 'Math 101',
            'section' => 'A',
        ]);

        // 3. Create Students and attach to Classroom
        $students = Student::factory(5)->create();
        $classroom->students()->attach($students);

        $this->command->info('Classroom "Math 101" created with 5 students.');

        // 4. Create an Exam
        $exam = Exam::create([
            'user_id' => $user->id,
            'name' => 'Midterm Exam',
            'date' => now(),
            'omr_code' => '20',
        ]);

        // 5. Create Questions for the Exam
        $questions = [];
        $answers = ['A', 'B', 'C', 'D', 'E'];
        
        for ($i = 1; $i <= 20; $i++) {
            $questions[] = [
                'question_number' => $i,
                'correct_answer' => $answers[array_rand($answers)], // Random answer
                'points' => 1,
            ];
        }
        
        $exam->questions()->createMany($questions);

        $this->command->info('Exam "Midterm Exam" created with 20 questions.');
    }
}
