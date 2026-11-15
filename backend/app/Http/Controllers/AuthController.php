<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate(['name' => 'required|string|max:255', 'email' => 'required|email|max:255|unique:users', 'password' => 'required|string|min:8|max:255|confirmed']);
        $user = User::create([...$data, 'role' => 'employee']);

        return response()->json(['user' => $user, 'token' => $user->createToken('mobile', ['*'], now()->addDays(30))->plainTextToken], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate(['email' => 'required|email', 'password' => 'required|string']);
        $user = User::where('email', $data['email'])->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['email' => ['Credenciais inválidas.']]);
        }

        return ['user' => $user, 'token' => $user->createToken('mobile', ['*'], now()->addDays(30))->plainTextToken];
    }

    public function profile(Request $request)
    {
        return $request->user();
    }

    public function updateProfile(Request $request)
    {
        $data = $request->validate(['name' => 'required|string|max:255', 'email' => ['required', 'email', 'max:255', Rule::unique('users')->ignore($request->user()->id)]]);
        $request->user()->update($data);

        return $request->user();
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->noContent();
    }
}
