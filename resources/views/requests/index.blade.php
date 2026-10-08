@extends('layouts.requests')

@section('title', 'Service requests')

@section('content')
    <div class="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
            <p class="mb-2 text-sm font-medium text-muted-foreground">Campus services</p>
            <h1 class="text-3xl font-semibold tracking-tight">Service requests</h1>
            <p class="mt-2 max-w-2xl text-muted-foreground">
                Track submitted requests and check their latest status.
            </p>
        </div>
        <span class="inline-flex w-fit items-center rounded-full bg-secondary px-3 py-1 text-sm font-medium text-secondary-foreground">
            {{ $requests->total() }} {{ \Illuminate\Support\Str::plural('request', $requests->total()) }}
        </span>
    </div>

    <div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_21rem]">
        <section class="overflow-hidden rounded-2xl border border-border bg-card text-card-foreground">
            <div class="border-b border-border px-5 py-4 sm:px-6">
                <h2 class="font-semibold">Recent requests</h2>
                <p class="mt-1 text-sm text-muted-foreground">Your latest submissions and their progress.</p>
            </div>

            @if ($requests->isEmpty())
                <div class="px-6 py-14 text-center">
                    <div class="mx-auto mb-4 flex size-12 items-center justify-center rounded-full bg-secondary text-lg font-semibold text-secondary-foreground">—</div>
                    <h3 class="font-semibold">No requests yet</h3>
                    <p class="mt-1 text-sm text-muted-foreground">New service requests will appear here.</p>
                </div>
            @else
                <div class="overflow-x-auto">
                    <table class="w-full min-w-[42rem] text-left text-sm">
                        <thead class="bg-muted/50 text-xs uppercase tracking-wide text-muted-foreground">
                            <tr>
                                <th scope="col" class="px-6 py-3 font-medium">Item</th>
                                <th scope="col" class="px-6 py-3 font-medium">Requester</th>
                                <th scope="col" class="px-6 py-3 font-medium">Submitted</th>
                                <th scope="col" class="px-6 py-3 font-medium">Status</th>
                                <th scope="col" class="px-6 py-3"><span class="sr-only">Details</span></th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-border">
                            @foreach ($requests as $serviceRequest)
                                <tr class="transition hover:bg-muted/30">
                                    <td class="px-6 py-4">
                                        <p class="font-medium">{{ $serviceRequest->item_name }}</p>
                                        <p class="mt-1 text-xs text-muted-foreground">Quantity: {{ $serviceRequest->quantity }}</p>
                                    </td>
                                    <td class="px-6 py-4">
                                        <p>{{ $serviceRequest->requester_name }}</p>
                                        <p class="mt-1 text-xs text-muted-foreground">{{ $serviceRequest->requester_email }}</p>
                                    </td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ $serviceRequest->created_at->format('M j, Y') ?? 'N/A' }}</td>
                                    <td class="px-6 py-4">
                                        <span @class([
                                            'inline-flex rounded-full px-2.5 py-1 text-xs font-medium capitalize',
                                            'bg-amber-500/10 text-amber-700 dark:text-amber-300' => $serviceRequest->status === 'pending',
                                            'bg-emerald-500/10 text-emerald-700 dark:text-emerald-300' => $serviceRequest->status === 'approved',
                                            'bg-red-500/10 text-red-700 dark:text-red-300' => $serviceRequest->status === 'rejected',
                                        ])>
                                            {{ $serviceRequest->status }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 text-right">
                                        <a href="{{ route('requests.show', $serviceRequest) }}" class="font-medium text-foreground underline-offset-4 hover:underline">
                                            View
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
                @if ($requests->hasPages())
                    <div class="border-t border-border px-5 py-4 sm:px-6">
                        {{ $requests->links() }}
                    </div>
                @endif
            @endif
        </section>

        @can('create', \App\Models\ServiceRequest::class)
            <section class="h-fit rounded-2xl border border-border bg-card p-5 text-card-foreground sm:p-6">
                <div class="mb-5">
                    <p class="text-sm font-medium text-muted-foreground">Have a need?</p>
                    <h2 class="mt-1 text-xl font-semibold">Create a request</h2>
                    <p class="mt-2 text-sm text-muted-foreground">Tell us what you need and how it will be used.</p>
                </div>

                <form method="POST" action="{{ route('requests.store') }}" class="space-y-4">
                    @csrf
                    <div>
                        <label for="item_name" class="mb-1.5 block text-sm font-medium">Item or service</label>
                        <input id="item_name" name="item_name" type="text" value="{{ old('item_name') }}" required maxlength="150" placeholder="e.g. Lab equipment"
                            @class([
                                'w-full rounded-lg border bg-background px-3 py-2.5 text-sm outline-none transition placeholder:text-muted-foreground focus:ring-2 focus:ring-ring',
                                'border-destructive' => $errors->has('item_name'),
                                'border-input' => ! $errors->has('item_name'),
                            ])>
                        @error('item_name')
                            <p class="mt-1.5 text-xs text-destructive">{{ $message }}</p>
                        @enderror
                    </div>

                    <div>
                        <label for="quantity" class="mb-1.5 block text-sm font-medium">Quantity</label>
                        <input id="quantity" name="quantity" type="number" value="{{ old('quantity', 1) }}" required min="1" step="1"
                            @class([
                                'w-full rounded-lg border bg-background px-3 py-2.5 text-sm outline-none transition focus:ring-2 focus:ring-ring',
                                'border-destructive' => $errors->has('quantity'),
                                'border-input' => ! $errors->has('quantity'),
                            ])>
                        @error('quantity')
                            <p class="mt-1.5 text-xs text-destructive">{{ $message }}</p>
                        @enderror
                    </div>

                    <div>
                        <label for="purpose" class="mb-1.5 block text-sm font-medium">Purpose</label>
                        <textarea id="purpose" name="purpose" rows="4" required maxlength="1000" placeholder="How will this item or service be used?"
                            @class([
                                'w-full resize-y rounded-lg border bg-background px-3 py-2.5 text-sm outline-none transition placeholder:text-muted-foreground focus:ring-2 focus:ring-ring',
                                'border-destructive' => $errors->has('purpose'),
                                'border-input' => ! $errors->has('purpose'),
                            ])>{{ old('purpose') }}</textarea>
                        @error('purpose')
                            <p class="mt-1.5 text-xs text-destructive">{{ $message }}</p>
                        @enderror
                    </div>

                    <button type="submit" class="w-full rounded-lg bg-primary px-4 py-2.5 text-sm font-semibold text-primary-foreground transition hover:opacity-90">
                        Submit request
                    </button>
                </form>
            </section>
        @endcan
    </div>
@endsection
