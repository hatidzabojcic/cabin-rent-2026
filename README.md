# CabinRent 2026

Seminarski rad iz predmeta Razvoj softvera II. Sistem omogućava pretragu i rezervaciju vikendica, Stripe testno plaćanje, upravljanje objektima i rezervacijama, obavijesti preko RabbitMQ-a, izvještaje i preporuke za goste.

## Tehnologije i arhitektura

- ASP.NET Core 10 REST API
- Entity Framework Core i Microsoft SQL Server
- RabbitMQ i odvojeni `CabinRent.Notifications` worker servis
- Flutter Android aplikacija za goste
- Flutter Windows desktop aplikacija za administratore i izdavače
- Stripe testno okruženje za plaćanje i refund
- Docker Compose za API, bazu, RabbitMQ i notification worker

## Struktura repozitorija

```text
backend/
  CabinRent.API/             REST API i composition root
  CabinRent.Model/           DTO modeli, requesti i paginacija
  CabinRent.Services/        servisni interfejsi i poslovni ugovori
  CabinRent.Infrastructure/  EF Core, poslovna pravila i integracije
  CabinRent.Notifications/   RabbitMQ consumer u zasebnom kontejneru
frontend/
  cabinrent_mobile/          Flutter Android aplikacija za goste
  cabinrent_desktop/         Flutter Windows aplikacija za Admin/Owner uloge
tests/CabinRent.UnitTests/    backend unit testovi
docs/                        razvojna, API i submission dokumentacija
```

## Preduvjeti

- Git, Docker Desktop, .NET 10 SDK i Flutter SDK
- Visual Studio Code sa C# Dev Kit, Flutter, Docker i MSSQL ekstenzijama
- Za Windows Flutter build: Visual Studio Build Tools/Community sa `Desktop development with C++`, MSVC v143 i Windows 10 SDK
- Za Android: Android SDK i emulator (preporučeno API 35)

Visual Studio IDE nije potreban za svakodnevni rad; projekat se može pokretati iz terminala u Visual Studio Codeu.

## Konfiguracija i backend

Sve osjetljive i promjenjive vrijednosti nalaze se u root `.env` datoteci:

```powershell
Copy-Item .env.example .env
```

Za Stripe plaćanje u `.env` unesi testne `STRIPE_SECRET_KEY` i `STRIPE_PUBLISHABLE_KEY` vrijednosti. Zatim pokreni:

```powershell
docker compose up --build -d
docker compose ps
```

- API i Swagger: `http://localhost:8080/swagger`
- health: `http://localhost:8080/health`
- SQL Server: `localhost,1433`, baza `IB160182`
- RabbitMQ konzola: `http://localhost:15672`

API automatski primjenjuje EF Core migracije i idempotentno dodaje seed podatke. Logovi:

```powershell
docker compose logs cabinrent-api --tail 200
docker compose logs cabinrent-notifications --tail 200
```

## Razvojni računi

| Klijent/uloga | Korisničko ime | Lozinka |
|---|---|---|
| Desktop – administrator | `admin` | `Admin123!` |
| Desktop – izdavač | `owner` | `Owner123!` |
| Desktop – drugi izdavač | `owner2` | `Owner2_123!` |
| Mobilna – gost | `guest` | `Guest123!` |

Lozinke se prilikom seeda hashiraju PBKDF2-SHA256 algoritmom. Izvor razvojnih vrijednosti je `.env`.

## Mobilna aplikacija

```powershell
cd frontend\cabinrent_mobile
flutter pub get
flutter emulators --launch CabinRent_API_35
flutter devices
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Ako emulator dobije drugi ID, koristi ID prikazan naredbom `flutter devices`. U aktivnom terminalu `r` radi hot reload, a `R` hot restart.

## Desktop aplikacija

```powershell
cd frontend\cabinrent_desktop
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

## Stripe testno plaćanje

Standardno plaćanje i refund koriste server-side Stripe provjeru i ne zahtijevaju ručno pokretanje webhook listenera.

- kartica: `4242 4242 4242 4242`
- datum isteka: bilo koji budući datum, npr. `12/34`
- CVC: bilo koja tri broja

Opcionalno asinhrono webhook testiranje:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\start-stripe-webhook.ps1
```

## Automatske provjere

```powershell
dotnet test CabinRent.sln
cd frontend\cabinrent_mobile
flutter analyze
flutter test
cd ..\cabinrent_desktop
flutter analyze
flutter test
```

## Release buildovi

```powershell
cd frontend\cabinrent_mobile
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8080

cd ..\cabinrent_desktop
flutter clean
flutter pub get
flutter build windows --release --dart-define=API_BASE_URL=http://localhost:8080
```

APK se nalazi u `frontend/cabinrent_mobile/build/app/outputs/flutter-apk/app-release.apk`, a Windows build u `frontend/cabinrent_desktop/build/windows/x64/runner/Release`.

Buildovi se ne commitaju. APK i cijeli Windows `Release` folder pakuju se u `fit-build-YYYY-MM-DD.zip` i postavljaju kao asset tačnog GitHub Releasea.

## Dokumentacija

- [Lokalni razvoj](docs/local-development.md)
- [Pregled API-ja](docs/api-overview.md)
- [Model baze](docs/database-design.md)
- [Sistem preporuke](recommender-dokumentacija.md)
- [Završna provjera predaje](docs/submission-checklist.md)

`.env` se nikada ne commita. Za finalnu predaju koristi se šifrovana `.env-tajne.zip`, a šifra se dostavlja isključivo kroz DLWMS.
