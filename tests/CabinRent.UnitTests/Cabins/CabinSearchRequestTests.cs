using CabinRent.Infrastructure.Cabins;
using CabinRent.Model.Cabins;
using Xunit;

namespace CabinRent.UnitTests.Cabins;

public sealed class CabinSearchRequestTests
{
    [Fact]
    public void Defaults_StartAtFirstPageWithTwentyItems()
    {
        var request = new CabinSearchRequest();

        Assert.Equal(1, request.Page);
        Assert.Equal(20, request.PageSize);
    }

    [Theory]
    [MemberData(nameof(InvalidSearchRequests))]
    public void Invalid_search_filters_are_rejected(
        CabinSearchRequest request,
        string expectedMessage)
    {
        var error = CabinSearchRules.GetValidationError(
            request,
            new DateOnly(2026, 9, 5));

        Assert.Equal(expectedMessage, error);
    }

    [Fact]
    public void Valid_search_filters_are_accepted()
    {
        var request = new CabinSearchRequest
        {
            CheckIn = new DateOnly(2026, 9, 5),
            CheckOut = new DateOnly(2026, 9, 8),
            Guests = 2,
            MinPrice = 100,
            MaxPrice = 250
        };

        var error = CabinSearchRules.GetValidationError(
            request,
            new DateOnly(2026, 9, 5));

        Assert.Null(error);
    }

    public static TheoryData<CabinSearchRequest, string> InvalidSearchRequests => new()
    {
        {
            new CabinSearchRequest { CheckIn = new DateOnly(2026, 9, 10) },
            "Datum dolaska i datum odlaska moraju biti uneseni zajedno."
        },
        {
            new CabinSearchRequest { CheckOut = new DateOnly(2026, 9, 10) },
            "Datum dolaska i datum odlaska moraju biti uneseni zajedno."
        },
        {
            new CabinSearchRequest
            {
                CheckIn = new DateOnly(2026, 9, 10),
                CheckOut = new DateOnly(2026, 9, 10)
            },
            "Datum odlaska mora biti nakon datuma dolaska."
        },
        {
            new CabinSearchRequest
            {
                CheckIn = new DateOnly(2026, 9, 1),
                CheckOut = new DateOnly(2026, 9, 3)
            },
            "Termin pretrage ne može biti u prošlosti."
        },
        {
            new CabinSearchRequest { Guests = 0 },
            "Broj gostiju mora biti najmanje 1."
        },
        {
            new CabinSearchRequest { MinPrice = -1 },
            "Cijena ne može biti negativna."
        },
        {
            new CabinSearchRequest { MaxPrice = -1 },
            "Cijena ne može biti negativna."
        },
        {
            new CabinSearchRequest { MinPrice = 300, MaxPrice = 200 },
            "Minimalna cijena ne može biti veća od maksimalne cijene."
        }
    };
}
