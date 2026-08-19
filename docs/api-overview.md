# API pregled

Swagger je dostupan na `http://localhost:8080/swagger` dok je razvojno okruženje pokrenuto.

## Autentifikacija

- `POST /api/Auth/login` — korisničko ime i lozinka
- `POST /api/Auth/register` — registruje novog korisnika s ulogom `Guest`
- `POST /api/Auth/refresh` — rotira refresh token i izdaje novi access token
- `POST /api/Auth/logout` — opoziva refresh token; zahtijeva access token
- `GET /api/Auth/me` — trenutno prijavljeni korisnik

Access token traje 15 minuta, a refresh token 7 dana. Refresh token se u bazi čuva samo kao SHA-256 hash i rotira nakon svake upotrebe. Ponovna upotreba starog tokena opoziva aktivne tokene te sesije.

U Swaggeru prvo izvrši login, kopiraj `accessToken`, klikni `Authorize` i zalijepi samo token, bez ručnog dodavanja riječi `Bearer`.

## Vikendice

- `GET /api/Cabins` — paginacija i filteri po tekstu, gradu, terminu, broju gostiju i cijeni
- `GET /api/Cabins/{id}` — javni detalji vikendice
- `GET /api/Cabins/manage` — Admin/Owner paginirani pregled
- `POST/PUT/DELETE /api/Cabins` — upravljanje vikendicama
- `POST/PATCH/DELETE /api/Cabins/{id}/images` — autorizovana galerija do 12 slika

## Katalozi

- `GET /api/catalog/countries`
- `GET /api/catalog/cities?countryId=&search=`
- `GET /api/catalog/cabin-types`
- `GET /api/catalog/amenities`
- `GET /api/catalog/roles`

## Korisnici — Admin

- `GET /api/Users?search=&role=` — lista bez osjetljivih podataka
- `GET /api/Users/{id}`
- `GET /api/Users/management` — paginacija, pretraga, uloga i status
- `POST/PUT/DELETE /api/Users` — administrativni CRUD
- `PATCH /api/Users/{id}/status` — aktivacija/deaktivacija

## Rezervacije — prijavljeni korisnici

- `GET /api/Reservations?cabinId=&status=` — Guest vidi svoje, Owner rezervacije svojih vikendica, Admin sve
- `GET /api/Reservations/{id}`
- `POST /api/Reservations` — Guest; identitet gosta se uzima iz tokena
- `PATCH /api/Reservations/{id}/status` — Owner vlastite vikendice ili Admin

Dozvoljeni statusi: `Pending`, `Confirmed`, `Cancelled`, `Completed`, `Rejected`.

## Recenzije

- `GET /api/Reviews?cabinId=&approved=`
- `POST /api/Reviews` — Guest; dozvoljen samo vlasniku završene rezervacije bez postojeće recenzije
- `GET /api/Reviews/management` — Admin/Owner filteri i paginacija
- `PUT/DELETE /api/Reviews/{id}` — vlasnik recenzije ili Admin
- `PATCH /api/Reviews/{id}/approval` — moderacija

## Favoriti

- `GET /api/Favorites` — favoriti trenutno prijavljenog gosta
- `POST /api/Favorites`
- `DELETE /api/Favorites/{cabinId}`

Javni su pregled vikendica i odobrenih recenzija te login/register/refresh. Ostali endpointi zahtijevaju odgovarajuću prijavu; bez tokena vraćaju `401`, a korisnik bez potrebne uloge dobija `403`.

## Plaćanja

- `POST /api/Payments/reservations/{id}/intent` — kreiranje Stripe PaymentIntenta
- `POST /api/Payments/reservations/{id}/confirm` — server-side potvrda stanja
- `POST /api/Payments/webhook` — Stripe potpisani webhook
- otkazivanje plaćene rezervacije pokreće stvarni Stripe testni refund

## Preporuke, obavijesti i novosti

- `GET /api/Recommendations` — Guest, paginirane personalizirane/fallback preporuke
- `GET /api/Notifications` i `/summary` — obavijesti trenutnog korisnika
- `PATCH /api/Notifications/{id}/read` i `/read-all`
- `GET /api/Announcements` — samo aktivne objavljene novosti
- `GET /api/Announcements/management` i `POST/PUT/DELETE` — Admin CRUD

## Izvještaji

- `GET /api/Reports/annual` — godišnji pregled rezervacija i prihoda
- `GET /api/Reports/top-guests` — rang-lista gostiju uz kriterije

Desktop klijent generiše, sprema i štampa PDF prikaz rezultata.
