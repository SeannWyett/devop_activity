@extends('layouts.requests')

@section('title', 'Request details')

@section('content')
    <a href="{{ route('requests.index') }}" class="mb-6 inline-flex items-center gap-2 text-sm font-medium text-muted-foreground transition hover:text-foreground">
        <span aria-hidden="true">←</span>
        Back to requests
    </a>

    <div class="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div>
            <p class="mb-2 text-sm font-medium text-muted-foreground">Request #{{ $serviceRequest->id }}</p>
            <h1 class="text-3xl font-semibold tracking-tight">{{ $serviceRequest->item_name }}</h1>
            <p class="mt-2 text-muted-foreground">Submitted {{ $serviceRequest->created_at->format('F j, Y \a\t g:i A') }}</p>
        </div>
        <span @class([
            'inline-flex w-fit rounded-full px-3 py-1.5 text-sm font-medium capitalize',
            'bg-amber-500/10 text-amber-700 dark:text-amber-300' => $serviceRequest->status === 'pending',
            'bg-emerald-500/10 text-emerald-700 dark:text-emerald-300' => $serviceRequest->status === 'approved',
            'bg-red-500/10 text-red-700 dark:text-red-300' => $serviceRequest->status === 'rejected',
        ])>
            {{ $serviceRequest->status }}
        </span>
    </div>

    <div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_21rem]">
        <section class="rounded-2xl border border-border bg-card p-5 text-card-foreground sm:p-6">
            <h2 class="text-lg font-semibold">Request details</h2>
            <dl class="mt-5 grid gap-5 sm:grid-cols-2">
                <div>
                    <dt class="text-sm text-muted-foreground">Requested item or service</dt>
                    <dd class="mt-1 font-medium">{{ $serviceRequest->item_name }}</dd>
                </div>
                <div>
                    <dt class="text-sm text-muted-foreground">Quantity</dt>
                    <dd class="mt-1 font-medium">{{ $serviceRequest->quantity }}</dd>
                </div>
                <div>
                    <dt class="text-sm text-muted-foreground">Requester</dt>
                    <dd class="mt-1 font-medium">{{ $serviceRequest->requester_name }}</dd>
                </div>
                <div>
                    <dt class="text-sm text-muted-foreground">Email</dt>
                    <dd class="mt-1 break-all font-medium">{{ $serviceRequest->requester_email }}</dd>
                </div>
                <div class="sm:col-span-2">
                    <dt class="text-sm text-muted-foreground">Purpose</dt>
                    <dd class="mt-2 whitespace-pre-line leading-7">{{ $serviceRequest->purpose }}</dd>
                </div>
            </dl>
        </section>

        @can('updateStatus', $serviceRequest)
            <section class="h-fit rounded-2xl border border-border bg-card p-5 text-card-foreground sm:p-6">
                <p class="text-sm font-medium text-muted-foreground">Administrator</p>
                <h2 class="mt-1 text-xl font-semibold">Update status</h2>
                <p class="mt-2 text-sm text-muted-foreground">Choose the current decision for this request.</p>

                <form method="POST" action="{{ route('requests.update-status', $serviceRequest) }}" class="mt-5 space-y-4">
                    @csrf
                    @method('PATCH')
                    <div>
                        <label for="status" class="mb-1.5 block text-sm font-medium">Status</label>
                        <select id="status" name="status" required class="w-full rounded-lg border border-input bg-background px-3 py-2.5 text-sm outline-none transition focus:ring-2 focus:ring-ring">
                            @foreach (['pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected', 'banana' => 'Banana'] as $statusValue => $statusLabel)
                                <option value="{{ $statusValue }}" @selected(old('status', $serviceRequest->status) === $statusValue)>
                                    {{ $statusLabel }}
                                </option>
                            @endforeach
                        </select>
                        @error('status')
                            <p class="mt-1.5 text-xs text-destructive">{{ $message }}</p>
                        @enderror
                    </div>
                    <button type="submit" class="w-full rounded-lg bg-primary px-4 py-2.5 text-sm font-semibold text-primary-foreground transition hover:opacity-90">
                        Save status
                    </button>
                </form>
            </section>
        @endcan
    </div>
@endsection
