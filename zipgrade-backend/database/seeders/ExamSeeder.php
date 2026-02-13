<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Exam;
use App\Models\Question;

class ExamSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Ensure we have a user to attach exams to
        $user = User::first();
        if (!$user) {
            $user = User::factory()->create([
                'name' => 'Test Teacher',
                'email' => 'teacher@example.com',
                'password' => bcrypt('password'),
            ]);
        }

        $configs = [
            ['items' => 25, 'name' => '25 Item Quiz'],
            ['items' => 50, 'name' => '50 Item Midterm'],
        ];

        foreach ($configs as $config) {
            $exam = Exam::create([
                'user_id' => $user->id,
                'name' => $config['name'],
                'date' => now(),
                'omr_code' => (string)$config['items'], // Assuming omr_code matches item count for now
            ]);

            $questions = [];
            $answers = ['A', 'B', 'C', 'D', 'E'];

            for ($i = 1; $i <= $config['items']; $i++) {
                $questions[] = [
                    'question_number' => $i,
                    'correct_answer' => $answers[array_rand($answers)],
                    'points' => 1,
                ];
            }

            $exam->questions()->createMany($questions);
            $this->command->info("Created exam '{$config['name']}' with {$config['items']} questions.");
        }
    }
}
