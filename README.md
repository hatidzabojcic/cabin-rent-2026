# CabinRent 2026

Seminarski rad za upravljanje iznajmljivanjem vikendica. Repozitorij je organizovan kao ASP.NET Core 10 backend, notification worker i dva buduća Flutter klijenta.

## Struktura

```text
backend/
  CabinRent.API/             REST API i composition root
  CabinRent.Model/           DTO modeli, requesti i search objekti
  CabinRent.Services/        poslovna pravila i interfejsi
  CabinRent.Infrastructure/  EF Core, MSSQL i vanjske integracije
  CabinRent.Notifications/   budući RabbitMQ/email worker
frontend/
  cabinrent_mobile/          Flutter mobilna aplikacija
  cabinrent_desktop/         Flutter administratorska aplikacija
tests/                       backend test projekti
docs/                        projektna i baza dokumentacija
scripts/                     pomoćne razvojne skripte
```

## Brzi start

Preduvjeti: .NET 10 SDK i Docker Desktop.

```powershell
Copy-Item .env.example .env
docker compose up --build
```

API: `http://localhost:8080`

Swagger: `http://localhost:8080/swagger`

SQL Server: `localhost,1433`

Za lokalni razvoj bez Dockera podesiti `ConnectionStrings__DefaultConnection`, zatim:

```powershell
dotnet restore
dotnet build
dotnet run --project backend/CabinRent.API
```

Detalji početnog modela baze nalaze se u [docs/database-design.md](docs/database-design.md).
Kompletne VS Code upute i razvojni login podaci nalaze se u [docs/local-development.md](docs/local-development.md).
Pregled trenutno implementiranih endpointa nalazi se u [docs/api-overview.md](docs/api-overview.md).
