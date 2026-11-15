# Local Docker testing

Start Docker Desktop with its Linux container engine, then open PowerShell:

```powershell
cd "C:\Projeto Final\TechFix"
docker compose up --build -d --wait
docker compose ps
```

This builds the Laravel API and starts MySQL 8.4. Migrations run automatically before the API starts. XAMPP is not required. MySQL is available only inside the Compose network, so it does not conflict with XAMPP's port 3306. The API is available at http://localhost:8000/api; its health endpoint is http://localhost:8000/up.

This configuration is for local testing, with development credentials and debug mode enabled. It does not copy or change `backend/.env`. Database data and the application key persist in Docker volumes. Rebuild with `docker compose up --build -d --wait` after editing backend code.

## Verify and test

```powershell
Invoke-WebRequest http://localhost:8000/up
docker compose exec api php artisan migrate:status
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_api.ps1
docker compose exec api php vendor/phpunit/phpunit/phpunit --do-not-cache-result --testdox
docker compose exec api php artisan techfix:admin admin@example.com
```

The admin command prompts for a name and password. The PowerShell smoke test exercises the running MySQL API, then removes its customer, device and order and logs out. It leaves one uniquely named test employee. PHPUnit uses isolated in-memory SQLite. Use the Postman collection and `docs/DEMO.md` for further manual testing.

Flutter runs on the host or an Android device, outside these containers. For an Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Android SDK/platform setup is still required. The default API port binding is local only. Physical phone testing needs a LAN-accessible binding and firewall configuration.

## Logs and stopping

```powershell
docker compose logs --tail=100 api db
docker compose down
```

Stopping preserves database data. Avoid `docker compose down -v` unless you intend to delete this Docker test database and its stored application key.
