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
- `GET /api/Cabins/{id}` — sažeti detalji vikendice

## Katalozi

- `GET /api/catalog/countries`
- `GET /api/catalog/cities?countryId=&search=`
- `GET /api/catalog/cabin-types`
- `GET /api/catalog/amenities`
- `GET /api/catalog/roles`

## Korisnici — Admin

- `GET /api/Users?search=&role=` — lista bez osjetljivih podataka
- `GET /api/Users/{id}`

## Rezervacije — prijavljeni korisnici

- `GET /api/Reservations?cabinId=&status=` — Guest vidi svoje, Owner rezervacije svojih vikendica, Admin sve
- `GET /api/Reservations/{id}`
- `POST /api/Reservations` — Guest; identitet gosta se uzima iz tokena
- `PATCH /api/Reservations/{id}/status` — Owner vlastite vikendice ili Admin

Dozvoljeni statusi: `Pending`, `Confirmed`, `Cancelled`, `Completed`, `Rejected`.

## Recenzije

- `GET /api/Reviews?cabinId=&approved=`
- `POST /api/Reviews` — Guest; dozvoljen samo vlasniku završene rezervacije bez postojeće recenzije

## Favoriti

- `GET /api/Favorites` — favoriti trenutno prijavljenog gosta
- `POST /api/Favorites`
- `DELETE /api/Favorites/{cabinId}`

Javni su pregled vikendica, katalozi, pregled recenzija te login/register/refresh. Zaštićeni endpoint bez tokena vraća `401`, a korisnik bez potrebne uloge dobija `403`.
