using System.ComponentModel.DataAnnotations;
using CabinRent.Model.Cabins;
using Xunit;

namespace CabinRent.UnitTests.Cabins;

public sealed class SaveCabinRequestTests
{
    [Fact]
    public void Valid_request_passes_data_annotation_validation()
    {
        var request = ValidRequest();

        Assert.Empty(Validate(request));
    }

    [Fact]
    public void Invalid_capacity_and_price_are_rejected()
    {
        var request = new SaveCabinRequest
        {
            Name = "Test", Description = "Opis", Address = "Adresa",
            AreaSquareMeters = 50, PricePerNight = 0, MaxAdults = 0,
            MaxChildren = 0, Bedrooms = 1, Bathrooms = 1, CityId = 1, CabinTypeId = 1
        };

        var members = Validate(request).SelectMany(x => x.MemberNames).ToArray();

        Assert.Contains(nameof(SaveCabinRequest.PricePerNight), members);
        Assert.Contains(nameof(SaveCabinRequest.MaxAdults), members);
    }

    [Fact]
    public void Invalid_coordinates_are_rejected()
    {
        var request = ValidRequest().WithCoordinates(latitude: 91, longitude: -181);

        var members = Validate(request).SelectMany(x => x.MemberNames).ToArray();

        Assert.Contains(nameof(SaveCabinRequest.Latitude), members);
        Assert.Contains(nameof(SaveCabinRequest.Longitude), members);
    }

    private static SaveCabinRequest ValidRequest() => new()
    {
        Name = "Planinska kuća", Description = "Mirna lokacija", Address = "Planina 1",
        AreaSquareMeters = 80, PricePerNight = 180, MaxAdults = 4, MaxChildren = 2,
        Bedrooms = 2, Bathrooms = 1, CityId = 1, CabinTypeId = 1
    };

    private static IReadOnlyCollection<ValidationResult> Validate(SaveCabinRequest request)
    {
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(request, new ValidationContext(request), results, true);
        return results;
    }
}

internal static class SaveCabinRequestTestExtensions
{
    public static SaveCabinRequest WithCoordinates(this SaveCabinRequest request, double latitude, double longitude) => new()
    {
        Name = request.Name, Description = request.Description, Address = request.Address,
        AreaSquareMeters = request.AreaSquareMeters, PricePerNight = request.PricePerNight,
        MaxAdults = request.MaxAdults, MaxChildren = request.MaxChildren, Bedrooms = request.Bedrooms,
        Bathrooms = request.Bathrooms, CityId = request.CityId, CabinTypeId = request.CabinTypeId,
        Latitude = latitude, Longitude = longitude
    };
}
