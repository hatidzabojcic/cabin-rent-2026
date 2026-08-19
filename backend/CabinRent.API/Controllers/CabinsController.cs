using CabinRent.Model.Cabins;
using CabinRent.Model.Common;
using CabinRent.Services.Cabins;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;
using CabinRent.Infrastructure.Cabins;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class CabinsController(ICabinService cabinService, ICabinImageService imageService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<PagedResult<CabinDto>>(StatusCodes.Status200OK)]
    public Task<PagedResult<CabinDto>> Get([FromQuery] CabinSearchRequest request, CancellationToken cancellationToken) =>
        cabinService.GetAsync(request, cancellationToken);

    [HttpGet("{id:int}")]
    [ProducesResponseType<CabinDetailsDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CabinDetailsDto>> GetById(int id, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.GetByIdAsync(id, cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }

    [HttpGet("manage")]
    [Authorize(Roles = "Admin,Owner")]
    public Task<PagedResult<CabinDetailsDto>> GetManaged([FromQuery] PageRequest paging, CancellationToken cancellationToken) =>
        cabinService.GetManagedAsync(paging, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);

    [HttpGet("manage/{id:int}")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<CabinDetailsDto>> GetManagedById(int id, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.GetManagedByIdAsync(id, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Owner")]
    [ProducesResponseType<CabinDetailsDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<CabinDetailsDto>> Create(SaveCabinRequest request, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.CreateAsync(request, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return CreatedAtAction(nameof(GetManagedById), new { id = cabin.Id }, cabin);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<CabinDetailsDto>> Update(int id, SaveCabinRequest request, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.UpdateAsync(id, request, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }

    [HttpPatch("{id:int}/active")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<CabinDetailsDto>> SetActive(int id, SetCabinActiveRequest request, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.SetActiveAsync(id, request.IsActive, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }

    [HttpPost("{id:int}/images")]
    [Authorize(Roles = "Admin,Owner")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(8 * 1024 * 1024)]
    public async Task<ActionResult<CabinImageDto>> UploadImage(int id, IFormFile file, [FromForm] string? altText, CancellationToken cancellationToken)
    {
        if (file.Length == 0) return BadRequest("Odaberite sliku za upload.");
        if (file.Length > CabinImageRules.MaxFileSize) return BadRequest("Slika ne smije biti veća od 8 MB.");
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!CabinImageRules.IsSupported(extension, file.ContentType))
            return BadRequest("Dozvoljeni formati su JPG, PNG i WebP.");
        await using var stream = file.OpenReadStream();
        if (!await CabinImageRules.HasValidSignatureAsync(stream, extension, cancellationToken))
            return BadRequest("Sadrzaj datoteke ne odgovara odabranom formatu slike.");
        var image = await imageService.AddAsync(id, stream, extension, altText, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return StatusCode(StatusCodes.Status201Created, image);
    }

    [HttpPatch("{id:int}/images/{imageId:int}")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<CabinImageDto>> UpdateImage(int id, int imageId, UpdateCabinImageRequest request, CancellationToken cancellationToken)
    {
        var image = await imageService.UpdateAsync(id, imageId, request, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return image is null ? NotFound() : Ok(image);
    }

    [HttpDelete("{id:int}/images/{imageId:int}")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<IActionResult> DeleteImage(int id, int imageId, CancellationToken cancellationToken) =>
        await imageService.DeleteAsync(id, imageId, User.GetUserId(), User.IsInRole("Admin"), cancellationToken) ? NoContent() : NotFound();

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken) =>
        await cabinService.DeleteAsync(id, User.GetUserId(), User.IsInRole("Admin"), cancellationToken) ? NoContent() : NotFound();
}
