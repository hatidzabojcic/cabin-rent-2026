using CabinRent.Model.Cabins;
using CabinRent.Model.Common;
using CabinRent.Services.Cabins;
using Microsoft.AspNetCore.Mvc;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class CabinsController(ICabinService cabinService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<PagedResult<CabinDto>>(StatusCodes.Status200OK)]
    public Task<PagedResult<CabinDto>> Get([FromQuery] CabinSearchRequest request, CancellationToken cancellationToken) =>
        cabinService.GetAsync(request, cancellationToken);

    [HttpGet("{id:int}")]
    [ProducesResponseType<CabinDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CabinDto>> GetById(int id, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.GetByIdAsync(id, cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }
}
