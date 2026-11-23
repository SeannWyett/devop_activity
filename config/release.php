<?php

// Release identity baked into the image at build time (Dockerfile ARG -> ENV).
// Read through config() everywhere else in the application; env() is only used here.

return [
    'version' => env('APP_VERSION', 'unknown'),
    'commit' => env('GIT_SHA', 'unknown'),
];
