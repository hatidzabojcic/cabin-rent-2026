using CabinRent.Model.Catalog;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using CabinRent.Model.Common;
using Microsoft.AspNetCore.Authorization;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/catalog")]
[Authorize]
public sealed class CatalogController(IPlatformQueryService service, IReferenceDataService referenceDataService) : ControllerBase
{
    [HttpGet("countries")]
    public Task<PagedResult<CountryDto>> Countries([FromQuery] PageRequest paging, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetCountriesAsync(paging, search, cancellationToken);

    [HttpGet("cities")]
    public Task<PagedResult<CityDto>> Cities([FromQuery] PageRequest paging, [FromQuery] int? countryId, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetCitiesAsync(paging, countryId, search, cancellationToken);

    [HttpGet("cabin-types")]
    public Task<PagedResult<CabinTypeDto>> CabinTypes([FromQuery] PageRequest paging, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetCabinTypesAsync(paging, search, cancellationToken);

    [HttpGet("amenities")]
    public Task<PagedResult<AmenityDto>> Amenities([FromQuery] PageRequest paging, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetAmenitiesAsync(paging, search, cancellationToken);

    [HttpGet("roles")]
    public Task<PagedResult<RoleDto>> Roles([FromQuery] PageRequest paging, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetRolesAsync(paging, search, cancellationToken);

    [HttpPost("countries")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CountryDto>> CreateCountry(SaveCountryRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await referenceDataService.CreateCountryAsync(request, cancellationToken));

    [HttpPut("countries/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CountryDto>> UpdateCountry(int id, SaveCountryRequest request, CancellationToken cancellationToken)
    {
        var result = await referenceDataService.UpdateCountryAsync(id, request, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpDelete("countries/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteCountry(int id, CancellationToken cancellationToken) =>
        await referenceDataService.DeleteCountryAsync(id, cancellationToken) ? NoContent() : NotFound();

    [HttpPost("cities")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CityDto>> CreateCity(SaveCityRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await referenceDataService.CreateCityAsync(request, cancellationToken));

    [HttpPut("cities/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CityDto>> UpdateCity(int id, SaveCityRequest request, CancellationToken cancellationToken)
    {
        var result = await referenceDataService.UpdateCityAsync(id, request, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpDelete("cities/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteCity(int id, CancellationToken cancellationToken) =>
        await referenceDataService.DeleteCityAsync(id, cancellationToken) ? NoContent() : NotFound();

    [HttpPost("cabin-types")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CabinTypeDto>> CreateCabinType(SaveCabinTypeRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await referenceDataService.CreateCabinTypeAsync(request, cancellationToken));

    [HttpPut("cabin-types/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CabinTypeDto>> UpdateCabinType(int id, SaveCabinTypeRequest request, CancellationToken cancellationToken)
    {
        var result = await referenceDataService.UpdateCabinTypeAsync(id, request, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpDelete("cabin-types/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteCabinType(int id, CancellationToken cancellationToken) =>
        await referenceDataService.DeleteCabinTypeAsync(id, cancellationToken) ? NoContent() : NotFound();

    [HttpPost("amenities")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<AmenityDto>> CreateAmenity(SaveAmenityRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await referenceDataService.CreateAmenityAsync(request, cancellationToken));

    [HttpPut("amenities/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<AmenityDto>> UpdateAmenity(int id, SaveAmenityRequest request, CancellationToken cancellationToken)
    {
        var result = await referenceDataService.UpdateAmenityAsync(id, request, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpDelete("amenities/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteAmenity(int id, CancellationToken cancellationToken) =>
        await referenceDataService.DeleteAmenityAsync(id, cancellationToken) ? NoContent() : NotFound();

    [HttpPost("roles")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<RoleDto>> CreateRole(CreateRoleRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await referenceDataService.CreateRoleAsync(request, cancellationToken));

    [HttpPut("roles/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<RoleDto>> UpdateRole(int id, UpdateRoleRequest request, CancellationToken cancellationToken)
    {
        var result = await referenceDataService.UpdateRoleAsync(id, request, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpDelete("roles/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteRole(int id, CancellationToken cancellationToken) =>
        await referenceDataService.DeleteRoleAsync(id, cancellationToken) ? NoContent() : NotFound();
}
