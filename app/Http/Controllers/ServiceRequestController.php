<?php

namespace App\Http\Controllers;

use App\Models\ServiceRequest;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class ServiceRequestController extends Controller
{
    public function index(Request $request): View
    {
        Gate::authorize('viewAny', ServiceRequest::class);

        $user = $request->user();

        $query = ServiceRequest::query();

        if ($user->role === 'student') {
            $query->where('user_id', $user->id);
        }

        $requests = $query
            ->latest()
            ->paginate(10);

        return view('requests.index', [
            'requests' => $requests,
        ]);
    }

    public function show(ServiceRequest $serviceRequest): View
    {
        Gate::authorize('view', $serviceRequest);

        return view('requests.show', [
            'serviceRequest' => $serviceRequest,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        Gate::authorize('create', ServiceRequest::class);

        $validated = $request->validate([
            'item_name' => 'required|string|max:150',
            'quantity' => 'required|integer|min:1',
            'purpose' => 'required|string|max:1000',
        ]);

        $user = $request->user();

        $serviceRequest = ServiceRequest::create([
            'user_id' => $user->id,
            'requester_name' => $user->name,
            'requester_email' => $user->email,
            'item_name' => $validated['item_name'],
            'quantity' => $validated['quantity'],
            'purpose' => $validated['purpose'],
            'status' => 'pending',
        ]);

        return redirect()->route('requests.show', $serviceRequest)
            ->with('success', 'Service request created successfully.');
    }

    public function updateStatus(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        Gate::authorize('updateStatus', $serviceRequest);

        $validated = $request->validate([
            'status' => 'required|in:pending,approved,rejected',
        ]);

        $serviceRequest->update([
            'status' => $validated['status'],
        ]);

        return redirect()->route('requests.show', $serviceRequest)
            ->with('success', 'Service request status updated successfully.');
    }
}
