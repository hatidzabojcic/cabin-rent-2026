using CabinRent.Model.Catalog;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/catalog")]
public sealed class CatalogController(IPlatformQueryService service) : ControllerBase
{
    [HttpGet("countries")]
    public Task<IReadOnlyCollection<CountryDto>> Countries(CancellationToken cancellationToken) => service.GetCountriesAsync(cancellationToken);

    [HttpGet("cities")]
    public Task<IReadOnlyCollection<CityDto>> Cities([FromQuery] int? countryId, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetCitiesAsync(countryId, search, cancellationToken);

    [HttpGet("cabin-types")]
    public Task<IReadOnlyCollection<CabinTypeDto>> CabinTypes(CancellationToken cancellationToken) => service.GetCabinTypesAsync(cancellationToken);

    [HttpGet("amenities")]
    public Task<IReadOnlyCollection<AmenityDto>> Amenities(CancellationToken cancellationToken) => service.GetAmenitiesAsync(cancellationToken);

    [HttpGet("roles")]
    public Task<IReadOnlyCollection<RoleDto>> Roles(CancellationToken cancellationToken) => service.GetRolesAsync(cancellationToken);
}
