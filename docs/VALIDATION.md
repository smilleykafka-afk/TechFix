# Validation report

## Optional device customer (2026-11-14)

- Device forms now allow an unassigned customer and no longer show an IMEI input. Existing customer links and legacy IMEI data are preserved.
- Added a migration making `aparelhos.cliente_id` nullable while retaining its foreign key. API validation accepts an omitted/null customer and rejects invalid customer IDs.
- Backend PHPUnit: 9 tests passed, 103 assertions, including an order for a device without a customer, assigning/unassigning a customer, and invalid customer validation.
- Laravel Pint check passed for changed PHP files.
- Docker rebuilt successfully and both services became healthy; migration applied on startup.
- Live MySQL API check passed: created a device without client/IMEI, created an order for it, then removed both temporary records and logged out.
- Flutter format/analyze/test execution was declined for this change, so those checks were not rerun.

## Docker setup (2026-11-14)

- Added a local Laravel API + MySQL 8.4 Compose environment; see [Docker testing](DOCKER.md).
- `docker compose config --quiet`: passed.
- Started Docker Desktop's Linux engine and built the API image successfully.
- `docker compose up -d --wait`: passed; API and MySQL containers healthy.
- MySQL migration status: all five migrations ran successfully.
- Containerized PHPUnit: 8 tests passed, 87 assertions (isolated in-memory SQLite).
- `tools/test_api.ps1`: passed against the running MySQL API after the final configuration fix, covering registration, employee role enforcement, bearer authentication, profile, customer/device/order creation, repair status history, dashboard, cleanup and logout.
- Fixed container application-key availability for `docker compose exec` commands. Added `--no-reload` to prevent Laravel's development server from stripping Docker environment variables when the container-local `.env` exists.
- Smoke-test business records were removed. Two test employee accounts from successful runs remain; their tokens were revoked by logout.
- Docker validation completes the MySQL check below for the container environment. Android build/device validation remains pending.

- `dart analyze lib test`: passed, no issues.
- `flutter test --no-pub`: 6 tests passed, covering validators, unauthenticated routing, loaded/empty/error UI states, bearer headers, secure token storage, logout, expired tokens, and malformed API responses.
- `php -d extension=pdo_sqlite vendor/phpunit/phpunit/phpunit --testdox`: 8 tests passed, 87 assertions. Six tests cover TechFix workflows; two are the Laravel starter checks.
- `php artisan route:list --path=api --except-vendor`: 12 route definitions, including parameterized resource CRUD.
- Dart files formatted and PHP application files formatted with Laravel Pint.
- Screenshots capture actual Flutter widgets with deterministic mocked API responses, not a live Android session.

## Remaining environment checks

- `flutter analyze` crashes inside the installed SDK's LSP JSON handshake on this accented Windows path. Direct `dart analyze lib test` succeeds.
- No MySQL server was listening on port 3306 during validation. Migrations and API workflows were tested using in-memory SQLite; MySQL execution is pending local database startup/configuration.
- Android platform generation was declined during the session. No Android build or emulator/device run was performed. Follow the README to generate the Android host project and configure networking.
- The Postman collection is delivered for manual use; Postman itself was not run. Automated Laravel feature tests exercise the endpoints instead.
