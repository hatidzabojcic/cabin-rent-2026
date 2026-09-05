# Završna provjera predaje

Ovo je jedini operativni checklist za finalnu predaju.

## Izvorni kod i konfiguracija

- [ ] `git status` je čist i završni commitovi su pushani.
- [ ] `.env` postoji lokalno, ali ga `git ls-files .env` ne prikazuje.
- [ ] Stripe testni ključevi su aktivni i nisu javno objavljeni.
- [ ] Napravljena je AES-256 šifrovana `.env-tajne.zip` u root folderu.
- [ ] Arhiva direktno sadrži `.env` i testno je raspakovana finalnom šifrom.
- [ ] Šifra je sačuvana za DLWMS i nije objavljena u repozitoriju.

## Docker i automatske provjere

```powershell
docker compose config
docker compose up --build -d
docker compose ps
Invoke-WebRequest http://localhost:8080/health
dotnet test CabinRent.sln
cd frontend\cabinrent_mobile
flutter analyze
flutter test
cd ..\cabinrent_desktop
flutter analyze
flutter test
```

- [ ] SQL, RabbitMQ, API i notification worker rade.
- [ ] Baza se zove `IB160182` i migracije/seed prolaze bez ručnih izmjena.
- [ ] Sve automatske provjere prolaze.

## Ručna provjera

> Napomena: nakon implementacije svih stavki iz feedbacka obavezno ručno proći kroz mobilnu i desktop aplikaciju te provjeriti kompletne korisničke tokove prije izrade finalnog releasea.

- [ ] Admin: korisnici/izdavači, šifrarnici, novosti, recenzije i izvještaji.
- [ ] Owner: vikendice i galerije, rezervacije, statusi i obavijesti.
- [ ] Guest: registracija, profil, pretraga, detalji, favoriti, preporuke, rezervacija, plaćanje, promjena termina, otkazivanje/refund, obavijesti i recenzija.
- [ ] Deaktivirani izdavač i njegove vikendice nisu dostupni za novu rezervaciju.
- [ ] Neaktivna novost se nakon osvježavanja ne prikazuje gostu.
- [ ] Promjena lozinke vraća korisnika na login i stara sesija više nije validna.

## Build i predaja

- [ ] Napravljen je i ručno provjeren Android release APK.
- [ ] Napravljen je i direktno pokrenut Windows desktop Release build.
- [ ] APK i cijeli desktop Release folder su u `fit-build-YYYY-MM-DD.zip`.
- [ ] `.env` i drugi nešifrovani osjetljivi fajlovi nisu u build arhivi.
- [ ] U GitHub Settings → Releases uključena je release immutability.
- [ ] Release je prvo kreiran kao draft i asset je provjeren prije objave.
- [ ] Na DLWMS je postavljen direktan `/releases/tag/...` link, ne `/releases/latest`.
- [ ] Na DLWMS je unesena šifra za `.env-tajne.zip`.
- [ ] Nakon roka nisu rađene izmjene repozitorija ni releasea.
