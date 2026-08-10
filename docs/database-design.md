# Početni model baze

Stara baza je imala dobru jezgru (`Korisnik`, `Klijent`, `Objekat`, `Rezervacija`, `Ocjena`, lokacije i uloge), ali je novi model normalizovan i pripremljen za siguran razvoj API-ja.

## Glavne odluke

- `Users` objedinjuje stare tabele `Korisnik` i `Klijent`; ponašanje određuju `Roles` i `UserRoles`.
- `Cabins` čuva numeričku površinu i cijenu (`decimal`), kapacitete, lokaciju i vlasnika. Zauzetost se ne čuva kao jedan boolean jer zavisi od perioda.
- `Reservations` čuva termin, broj gostiju, status, cijenu u trenutku rezervacije i jedinstveni kod potvrde.
- `Payments` je odvojen 1:1 zapis, spreman za Stripe ili drugi provider.
- `Reviews` je vezan za rezervaciju, čime se može dozvoliti samo jedna provjerena recenzija po boravku.
- `CabinImages`, `Amenities` i `CabinAmenities` zamjenjuju nejasnu staru tabelu `TipObjektaSllike`.
- `Favorites` omogućava korisničku listu želja.
- `AvailabilityBlocks` vlasniku omogućava zatvaranje termina bez lažne rezervacije.

## Pravila integriteta

- jedinstveni email i korisničko ime;
- datum odjave mora biti poslije prijave;
- najmanje jedna odrasla osoba i nenegativan broj djece;
- ocjena je između 1 i 5;
- jedna uplata i jedna recenzija po rezervaciji;
- novčane vrijednosti koriste `decimal`, ne `double`;
- preklapanje rezervacija provjerava servis u transakciji; SQL indeksi i konkurentnost bit će dodani uz prvu migraciju.

## Plan narednih backend faza

1. Početna EF Core migracija i seed uloga/admina.
2. JWT autentifikacija, refresh tokeni i autorizacija po ulogama.
3. CRUD za lokacije, sadržaje i vikendice.
4. Transakcijsko kreiranje rezervacije uz provjeru preklapanja.
5. Plaćanje, RabbitMQ događaji i email obavijesti.
6. Recenzije, favoriti, preporuke, izvještaji i testovi.
