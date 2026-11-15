<?php

use App\Models\User;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Validator;

Artisan::command('techfix:admin {email}', function () {
    $email = $this->argument('email');
    Validator::make(['email' => $email], ['email' => 'required|email'])->validate();
    $user = User::where('email', $email)->first();
    if (! $user) {
        $name = $this->ask('Administrator name');
        $password = $this->secret('Password (at least 12 characters)');
        Validator::make(compact('name', 'password'), ['name' => 'required|string|max:255', 'password' => 'required|string|min:12'])->validate();
        $user = User::create(compact('name', 'email', 'password'));
    }
    $user->update(['role' => 'admin']);
    $this->info('Administrator configured: '.$user->email);
})->purpose('Create or promote a TechFix administrator');
