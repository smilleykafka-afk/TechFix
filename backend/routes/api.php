<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\ResourceController;
use App\Models\Aparelho;
use App\Models\Cliente;
use App\Models\OrdemServico;
use App\Models\User;
use Illuminate\Support\Facades\Route;

Route::middleware('throttle:10,1')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
});
Route::middleware(['auth:sanctum', 'throttle:120,1'])->group(function () {
    Route::get('profile', [AuthController::class, 'profile']);
    Route::put('profile', [AuthController::class, 'updateProfile']);
    Route::post('logout', [AuthController::class, 'logout']);
    Route::get('employees', fn () => User::select('id', 'name')->orderBy('name')->get());
    Route::get('dashboard', fn () => [
        'customers' => Cliente::count(), 'devices' => Aparelho::count(),
        'open_orders' => OrdemServico::whereNotIn('status', ['completed', 'delivered', 'cancelled'])->count(),
        'completed_orders' => OrdemServico::whereIn('status', ['completed', 'delivered'])->count(),
    ]);
    Route::get('{resource}', [ResourceController::class, 'index']);
    Route::post('{resource}', [ResourceController::class, 'store']);
    Route::get('{resource}/{id}', [ResourceController::class, 'show'])->whereNumber('id');
    Route::put('{resource}/{id}', [ResourceController::class, 'update'])->whereNumber('id');
    Route::delete('{resource}/{id}', [ResourceController::class, 'destroy'])->whereNumber('id');
});
