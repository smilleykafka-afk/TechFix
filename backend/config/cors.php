<?php

return [
    'paths' => ['api/*'], 'allowed_methods' => ['*'],
    'allowed_origins' => explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost:3000,http://localhost:8080')),
    'allowed_origins_patterns' => [], 'allowed_headers' => ['Accept', 'Authorization', 'Content-Type'],
    'exposed_headers' => [], 'max_age' => 3600, 'supports_credentials' => false,
];
