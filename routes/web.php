<?php

use App\Http\Controllers\ServiceRequestController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::inertia('/', 'welcome')->name('home');

Route::middleware(['auth'])->group(function () {
    Route::inertia('dashboard', 'dashboard')->name('dashboard');
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

Route::get('/health', function () {
    try {
        DB::select('select 1');
        $database = 'ok';
    } catch (\Throwable $e) {
        $database = 'down';
    }

    return response()->json([
        'status' => $database === 'ok' ? 'ok' : 'degraded',
        'version' => config('release.version'),
        'commit' => config('release.commit'),
        'environment' => config('app.env'),
        'database' => $database,
    ], $database === 'ok' ? 200 : 503);
})->withoutMiddleware([
    \Illuminate\Session\Middleware\StartSession::class,
    \Illuminate\View\Middleware\ShareErrorsFromSession::class,
    \Illuminate\Foundation\Http\Middleware\PreventRequestForgery::class,
]);

require __DIR__.'/settings.php';
