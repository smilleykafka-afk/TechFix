# TechFix

Flutter Android application and Laravel 12 REST API for a mobile repair shop. TechFix uses MySQL and Sanctum bearer tokens, with all application data accessed through the Laravel API. Remaining UI examples from the original teaching scaffold are preserved in `docs/original-scaffold/` and excluded from analysis.

## Requirements

- Flutter with Dart 3.9 or later, Android SDK and an emulator or physical device.
- PHP 8.2+, Composer, MySQL 8+ (or compatible MariaDB). Enable PHP extensions `pdo_mysql`, `mbstring`, `openssl`, `fileinfo`, `dom`, `xml`, `zip`. Tests additionally use `pdo_sqlite`.
- The API and mobile app run as separate processes.

## Backend setup

For a containerized local API and MySQL environment, follow [Docker testing](docs/DOCKER.md). XAMPP is not required for that option.

```powershell
cd backend
composer install
Copy-Item .env.example .env
```

Create an empty MySQL database named `techfix`. Edit `backend/.env` with your MySQL host, username and password. Then:

```powershell
php artisan key:generate
php artisan migrate
php artisan techfix:admin admin@example.com
php artisan serve --host=0.0.0.0 --port=8000
```

The admin command prompts for a name and password, or promotes an existing account. There are no built-in administrator credentials. Public registration always creates an employee; administrators create and edit staff through the app. An administrator cannot delete or demote their own account. Changing another user's role or password revokes their existing tokens.

Use HTTPS and `APP_DEBUG=false` for deployment. `CORS_ALLOWED_ORIGINS` is a comma-separated list of exact permitted browser origins for future web clients. The mobile client uses bearer tokens, not browser cookie authentication. See [Laravel Sanctum documentation](https://laravel.com/framework/docs/12.x/sanctum).

## Flutter setup

```powershell
flutter pub get
flutter create --platforms=android --project-name techfix --org com.techfix .
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

`10.0.2.2` reaches the host computer from the Android emulator. For a physical phone use the computer's LAN IP and allow port 8000 through the local firewall. For a deployed API use its HTTPS URL. Platform generation was not authorized during this session, so the Android folder must first be generated with the command above. For local HTTP development add `android:usesCleartextTraffic="true"` to the application element in `android/app/src/debug/AndroidManifest.xml`; use HTTPS in release builds. Add the `android.permission.INTERNET` permission in the main manifest for release networking.

## Features

- Registration, login, secure token storage, session restoration, logout and protected named routes.
- Dashboard counts and shortcuts; customer/device/order CRUD with search, validation, loading, retry and empty states.
- Device/customer selectors (a device's customer is optional), responsible employee selector, seven repair statuses and status filtering. Device forms do not request an IMEI.
- Unique repair numbers, status history, price, diagnosis and notes.
- Profile editing, staff management for administrators and spare parts inventory CRUD.
- Foreign keys prevent deleting customers with devices or devices with orders. Delete dependents first; the API returns a readable conflict response.
- Employees manage shop customers, devices, repair orders and parts. Only administrators manage staff. This is a single-shop system: records are shared across staff, not isolated by account.

Inventory quantities are maintained manually; automatic part consumption and billing are outside this implementation. Repair history records creation and status changes. Public registration suits the requested classroom workflow; disable or restrict it before opening a private business deployment.

## Architecture

`lib/core/` holds theme, field definitions, constants, route names and validators without importing services/screens. `lib/models/` contains pure Dart JSON records. `lib/services/` owns HTTP, authentication and resource access; screens never call HTTP directly. App routing is composed in `lib/app_router.dart` to keep core independent. Shared CRUD screens use resource field metadata; repair details, authentication, dashboard and profile have dedicated screens.

## Checks and demonstration

```powershell
dart format lib test
dart analyze lib test
flutter analyze
flutter test
cd backend
php artisan test
```

On the installed Windows SDK, `flutter analyze` may crash in the LSP handshake when the workspace path contains accented characters. `dart analyze lib test` runs the analyzer successfully in that case. On XAMPP where SQLite is installed but disabled, run `php -d extension=pdo_sqlite vendor/phpunit/phpunit/phpunit` from `backend/`. Backend tests use an isolated in-memory SQLite database and never reset your MySQL database.

Import [the Postman collection](docs/TechFix.postman_collection.json), set `base_url` and your credentials, then run requests in order. The collection saves authentication tokens and generated record IDs. See [API documentation](docs/API.md) and [demonstration steps](docs/DEMO.md).

Generated screenshots are placed in `docs/screenshots/` by the screenshot widget test. These render the real widgets using deterministic test data; use the demo steps to verify a live MySQL/Android installation.
