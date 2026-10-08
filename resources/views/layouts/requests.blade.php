<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" @class(['dark' => ($appearance ?? 'system') == 'dark'])>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <script>
            (function () {
                const appearance = '{{ $appearance ?? "system" }}';

                if (appearance === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches) {
                    document.documentElement.classList.add('dark');
                }
            })();
        </script>

        <style>
            html {
                background-color: oklch(1 0 0);
            }

            html.dark {
                background-color: oklch(0.145 0 0);
            }
        </style>

        <link rel="icon" href="/favicon.ico" sizes="any">
        <link rel="icon" href="/favicon.svg" type="image/svg+xml">
        <link rel="apple-touch-icon" href="/apple-touch-icon.png">

        @fonts
        @vite('resources/css/app.css')

        <title>@yield('title', 'Service Requests') · {{ config('app.name', 'Laravel') }}</title>
    </head>
    <body class="min-h-screen bg-background font-sans text-foreground antialiased">
        <div class="min-h-screen">
            <header class="border-b border-border bg-background">
                <div class="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4 sm:px-6 lg:px-8">
                    <a href="{{ route('requests.index') }}" class="flex items-center gap-3 font-semibold tracking-tight">
                        <span class="flex size-9 items-center justify-center rounded-xl bg-primary text-sm font-bold text-primary-foreground">SR</span>
                        <span>{{ config('app.name', 'Campus Services') }}</span>
                    </a>
                    <div class="flex items-center gap-3 text-sm">
                        <span class="hidden text-muted-foreground sm:inline">{{ auth()->user()->name }}</span>
                        <form method="POST" action="{{ route('logout') }}">
                            @csrf
                            <button type="submit" class="rounded-lg border border-border px-3 py-2 font-medium transition hover:bg-accent hover:text-accent-foreground">
                                Sign out
                            </button>
                        </form>
                    </div>
                </div>
            </header>

            <main class="mx-auto max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
                @if (session('success'))
                    <div role="status" class="mb-6 rounded-xl border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-800 dark:text-emerald-300">
                        {{ session('success') }}
                    </div>
                @endif

                @if ($errors->any())
                    <div role="alert" class="mb-6 rounded-xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
                        <p class="font-semibold">Please check the information below.</p>
                        <ul class="mt-2 list-inside list-disc space-y-1">
                            @foreach ($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                @yield('content')
            </main>
        </div>
    </body>
</html>
