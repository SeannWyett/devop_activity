<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;

class Lab3UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::create([
            'name' => 'Student A',
            'email' => 'student.a@example.com',
            'password' => 'StudentA123!',
            'role' => 'student',
        ]);

        User::create([
            'name' => 'Student B',
            'email' => 'student.b@example.com',
            'password' => 'StudentB123!',
            'role' => 'student',
        ]);

        User::create([
            'name' => 'Administrator',
            'email' => 'admin@example.com',
            'password' => 'Admin123!',
            'role' => 'admin',
        ]);
    }
}
