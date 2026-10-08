<?php

use App\Http\Controllers\ServiceRequestController;
use Illuminate\Support\Facades\Route;

Route::inertia('/', 'welcome')->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::inertia('dashboard', 'dashboard')->name('requests.index  ');
});

Route::middleware('auth')->group(function () {
    Route::get('/requests', [ServiceRequestController::class, 'index'])
        ->name('requests.index');

    Route::get('/requests/{serviceRequest}', [ServiceRequestController::class, 'show'])
        ->name('requests.show');

    Route::post('/requests', [ServiceRequestController::class, 'store'])
        ->name('requests.store');

    Route::patch('/requests/{serviceRequest}/status', [ServiceRequestController::class, 'updateStatus'])
        ->name('requests.update-status');
});

Route::get('/_mw', fn () => app('router')->getMiddlewareGroups()['web']);

require __DIR__.'/settings.php';
