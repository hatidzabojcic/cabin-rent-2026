# CabinRent mobilna aplikacija

Flutter Android aplikacija namijenjena gostima CabinRent sistema.

## Pokretanje

Prvo iz korijena repozitorija pokrenite Docker servise. Zatim otvorite Android
emulator i u ovom folderu izvršite:

```powershell
flutter pub get
flutter run
```

Android emulator koristi `http://10.0.2.2:8080` za pristup API-ju koji radi na
računaru. Za fizički telefon navedite lokalnu IP adresu računara:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Telefon i računar moraju biti na istoj mreži, a port 8080 dostupan kroz firewall.
