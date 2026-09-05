using CabinRent.Model.Cabins;

namespace CabinRent.Infrastructure.Cabins;

public static class CabinSearchRules
{
    public static string? GetValidationError(CabinSearchRequest request, DateOnly today)
    {
        if (request.CheckIn.HasValue != request.CheckOut.HasValue)
            return "Datum dolaska i datum odlaska moraju biti uneseni zajedno.";

        if (request.CheckIn.HasValue && request.CheckOut.HasValue)
        {
            if (request.CheckOut.Value <= request.CheckIn.Value)
                return "Datum odlaska mora biti nakon datuma dolaska.";

            if (request.CheckIn.Value < today)
                return "Termin pretrage ne može biti u prošlosti.";
        }

        if (request.Guests is < 1)
            return "Broj gostiju mora biti najmanje 1.";

        if (request.MinPrice is < 0 || request.MaxPrice is < 0)
            return "Cijena ne može biti negativna.";

        if (request.MinPrice.HasValue && request.MaxPrice.HasValue &&
            request.MinPrice.Value > request.MaxPrice.Value)
            return "Minimalna cijena ne može biti veća od maksimalne cijene.";

        return null;
    }
}
