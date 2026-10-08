<?php

use App\Models\ServiceRequest;
use App\Models\User;

test('students can browse, create, and view their service requests', function () {
    $student = User::factory()->create(['role' => 'student']);

    $this->withoutVite()->actingAs($student);

    $this->get(route('requests.index'))
        ->assertOk()
        ->assertViewIs('requests.index')
        ->assertSee('Create a request');

    $response = $this->post(route('requests.store'), [
        'item_name' => 'Projector',
        'quantity' => 2,
        'purpose' => 'For the final presentation.',
    ]);

    $serviceRequest = ServiceRequest::query()->firstOrFail();

    $response->assertRedirect(route('requests.show', $serviceRequest));
    $this->assertDatabaseHas('requests', [
        'id' => $serviceRequest->id,
        'user_id' => $student->id,
        'item_name' => 'Projector',
        'quantity' => 2,
        'status' => 'pending',
    ]);

    $this->get(route('requests.show', $serviceRequest))
        ->assertOk()
        ->assertViewIs('requests.show')
        ->assertSee('Projector')
        ->assertSee('For the final presentation.');
});

test('administrators can update a service request status', function () {
    $admin = User::factory()->create(['role' => 'admin']);
    $student = User::factory()->create(['role' => 'student']);
    $serviceRequest = ServiceRequest::query()->create([
        'user_id' => $student->id,
        'requester_name' => $student->name,
        'requester_email' => $student->email,
        'item_name' => 'Projector',
        'quantity' => 1,
        'purpose' => 'For a presentation.',
        'status' => 'pending',
    ]);

    $this->withoutVite()
        ->actingAs($admin)
        ->get(route('requests.show', $serviceRequest))
        ->assertOk()
        ->assertViewIs('requests.show')
        ->assertSee('Update status');

    $this->patch(route('requests.update-status', $serviceRequest), [
        'status' => 'approved',
    ])->assertRedirect(route('requests.show', $serviceRequest));

    $this->assertDatabaseHas('requests', [
        'id' => $serviceRequest->id,
        'status' => 'approved',
    ]);
});
