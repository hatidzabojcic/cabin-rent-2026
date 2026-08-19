# Lokalni razvoj u Visual Studio Codeu

Za kompletan rad koristimo Visual Studio Code, ugrađeni terminal, Docker ekstenziju, C# Dev Kit i MSSQL ekstenziju. Visual Studio nije potreban.

## Razvojni pristupni podaci

Vrijednosti ispod služe isključivo lokalnom razvoju. Njihov trajni izvor je `.env.example`; nakon kopiranja možeš ih promijeniti u lokalnom `.env` fajlu.

| Namjena | Korisnik | Lozinka |
|---|---|---|
| Aplikacija – admin | `admin` | `Admin123!` |
| Aplikacija – vlasnik | `owner` | `Owner123!` |
| Aplikacija – drugi vlasnik | `owner2` | `Owner2_123!` |
| Aplikacija – gost | `guest` | `Guest123!` |
| SQL Server | `sa` | vrijednost `MSSQL_SA_PASSWORD` iz `.env` |
| RabbitMQ | vrijednost `RABBITMQ_USER` | vrijednost `RABBITMQ_PASSWORD` |

U bazi se aplikacijske lozinke nikada ne čuvaju kao tekst. Seed proces ih pretvara u PBKDF2-SHA256 hash. Promjena lozinke u `.env` ne mijenja već kreiranog korisnika; za to ćemo koristiti password-change/reset funkcionalnost.

## Stripe plaćanje i opcionalni webhook listener

Stripe CLI se lokalno čuva u ignorisanom folderu `.tools/stripe`, a ključevi u ignorisanoj `.env` datoteci.
Mobilna aplikacija nakon PaymentSheeta traži od API-ja server-side provjeru PaymentIntenta, pa osnovno plaćanje i refund rade bez ručnog pokretanja Stripe CLI-ja.

Za dodatno testiranje asinhronih Stripe webhook događaja iz root foldera projekta opcionalno pokrenite:

```powershell
.\scripts\start-stripe-webhook.ps1
```

Skripta pokreće listener za Stripe testni račun, ažurira `STRIPE_WEBHOOK_SECRET`, ponovo učitava samo API kontejner i provjerava `/health` endpoint. Vrijednosti ključeva se ne ispisuju u terminal. Webhook ostaje rezervni kanal za asinhrone promjene statusa i nije preduslov za standardni test plaćanja.

## Prvo pokretanje

```powershell
cd C:\github\cabin-rent-2026
Copy-Item .env.example .env
docker compose up --build
```

Nakon pokretanja:

- Swagger: `http://localhost:8080/swagger`
- health provjera: `http://localhost:8080/health`
- RabbitMQ konzola: `http://localhost:15672`
- MSSQL: `localhost,1433`

Za testiranje zaštićenih ruta u Swaggeru izvrši `POST /api/Auth/login`, kopiraj `accessToken`, klikni `Authorize` pri vrhu stranice i zalijepi token.

API pri pokretanju automatski primjenjuje samo migracije koje još nisu izvršene, a zatim idempotentno dodaje referentne i demo podatke.

## MSSQL ekstenzija u VS Codeu

1. Otvori Command Palette sa `Ctrl+Shift+P`.
2. Izaberi `MS SQL: Connect` ili `MSSQL: Connect`.
3. Kreiraj profil sa serverom `localhost`, portom `1433`, korisnikom `sa` i lozinkom iz `.env`.
4. Uključi `Trust server certificate`.
5. Nakon spajanja odaberi bazu `IB160182` (broj indeksa autora rada).
6. Kreiraj `.sql` datoteku i izvrši upite pomoću `MS SQL: Execute Query`.

```sql
SELECT * FROM dbo.__EFMigrationsHistory;
SELECT Id, UserName, Email, IsActive FROM dbo.Users;
SELECT * FROM dbo.Roles;
SELECT * FROM dbo.Countries;
SELECT * FROM dbo.Cities;
SELECT * FROM dbo.Amenities;
```

## Korisne naredbe

```powershell
docker compose ps
docker compose logs -f cabinrent-api
docker compose down
dotnet build
dotnet test
```

`docker compose down` čuva SQL podatke. Naredba `docker compose down -v` briše volumen i cijelu lokalnu bazu, pa je nemoj koristiti osim kada svjesno želiš čist početak.
