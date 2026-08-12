# CabinRent Desktop

Flutter Windows aplikacija za CabinRent administratore i vlasnike vikendica.

## Pokretanje

Iz korijena repozitorija prvo pokrenuti backend:

```powershell
docker compose up -d
```

Zatim iz ovog direktorija:

```powershell
flutter pub get
flutter run -d windows
```

Podrazumijevana API adresa je `http://localhost:8080`. Druga adresa se može
proslijediti bez promjene koda:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

## Razvojni loginovi

- Admin: `admin` / `Admin123!`
- Owner: `owner` / `Owner123!`

Refresh token se šifrira ugrađenim Windows DPAPI mehanizmom i vezan je za
trenutnog Windows korisnika. Access token se drži samo u memoriji aplikacije.
