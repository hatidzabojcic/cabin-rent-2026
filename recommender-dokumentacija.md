# Dokumentacija sistema preporuke

## Namjena i podaci

Sistem preporuke u mobilnoj aplikaciji gostu prikazuje aktivne, javno dostupne vikendice koje bi mu mogle odgovarati. Identitet korisnika uzima se iz JWT tokena. Koriste se završene rezervacije, favoriti, gradovi i tipovi ranije odabranih objekata, ponašanje drugih aktivnih gostiju, broj završenih boravaka te odobrene recenzije.

Iz kandidata se uklanjaju vikendice koje su već osnova korisnikovih preferencija, objekti s njegovom aktivnom rezervacijom i svi objekti koji nisu javno dostupni. Javna dostupnost zahtijeva aktivnu vikendicu i aktivnog izdavača.

## Bodovanje

```text
score = broj boravaka sličnih gostiju × 8
      + broj završenih boravaka × 3
      + prosječna ocjena × 2
      + min(broj recenzija, 10) × 0,25
      + podudaranje grada ili tipa × 1
```

Veća težina ponašanja sličnih gostiju daje personalizaciji prednost nad općom popularnošću. Rezultat se zaokružuje na dvije decimale. Sortiranje se zatim radi po rezultatu, prosječnoj ocjeni, broju završenih boravaka i nazivu.

Mobilni klijent prikazuje razlog preporuke: interesovanja sličnih gostiju, visoku ocjenu, popularnost, sličnost prethodno odabranim objektima ili opću popularnost među gostima.

## Novi korisnik i fallback

Kada gost nema završene rezervacije ni favorite, koristi se fallback zasnovan na odobrenim recenzijama i završenim boravcima. Ako nema aktivnosti, aktivne vikendice stabilno se sortiraju po rezultatu, ocjeni i nazivu. Polje `IsPersonalized` omogućava klijentu da razlikuje personalizirane rezultate od fallbacka.

## Paginacija i privatnost

Rezultati se vraćaju kao `PagedResult`, najviše 20 po stranici. Klijent ne šalje `userId`; servis ga uzima iz JWT tokena. Rezultat ne izlaže podatke drugih gostiju.

Relevantni dijelovi implementacije:

- `backend/CabinRent.API/Controllers/RecommendationsController.cs`
- `backend/CabinRent.Infrastructure/Recommendations/RecommendationService.cs`
- `backend/CabinRent.Infrastructure/Recommendations/RecommendationRules.cs`
- `frontend/cabinrent_mobile/lib/features/recommendations/`
- `tests/CabinRent.UnitTests/Recommendations/RecommendationRulesTests.cs`
