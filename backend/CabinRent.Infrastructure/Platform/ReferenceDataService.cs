using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Catalog;
using CabinRent.Services.Platform;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Platform;

public sealed class ReferenceDataService(CabinRentDbContext dbContext, ReferenceDataCacheState cacheState) : IReferenceDataService
{
    public async Task<CountryDto> CreateCountryAsync(SaveCountryRequest request, CancellationToken cancellationToken = default)
    {
        var name = Required(request.Name, "Naziv drzave");
        var isoCode = Required(request.IsoCode, "ISO oznaka").ToUpperInvariant();
        if (await dbContext.Countries.AnyAsync(x => x.Name == name || x.IsoCode == isoCode, cancellationToken))
            throw new BusinessRuleException("Drzava sa istim nazivom ili ISO oznakom vec postoji.");
        var entity = new Country { Name = name, IsoCode = isoCode };
        dbContext.Countries.Add(entity);
        await SaveChangesAsync(cancellationToken);
        return new CountryDto(entity.Id, entity.Name, entity.IsoCode);
    }

    public async Task<CountryDto?> UpdateCountryAsync(int id, SaveCountryRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.Countries.FindAsync([id], cancellationToken);
        if (entity is null) return null;
        var name = Required(request.Name, "Naziv drzave");
        var isoCode = Required(request.IsoCode, "ISO oznaka").ToUpperInvariant();
        if (await dbContext.Countries.AnyAsync(x => x.Id != id && (x.Name == name || x.IsoCode == isoCode), cancellationToken))
            throw new BusinessRuleException("Drzava sa istim nazivom ili ISO oznakom vec postoji.");
        entity.Name = name;
        entity.IsoCode = isoCode;
        entity.UpdatedAtUtc = DateTime.UtcNow;
        await SaveChangesAsync(cancellationToken);
        return new CountryDto(entity.Id, entity.Name, entity.IsoCode);
    }

    public async Task<bool> DeleteCountryAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.Countries.FindAsync([id], cancellationToken);
        if (entity is null) return false;
        if (await dbContext.Cities.AnyAsync(x => x.CountryId == id, cancellationToken))
            throw new BusinessRuleException("Drzavu nije moguce obrisati jer sadrzi gradove.");
        dbContext.Countries.Remove(entity);
        await SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<CityDto> CreateCityAsync(SaveCityRequest request, CancellationToken cancellationToken = default)
    {
        var country = await dbContext.Countries.FindAsync([request.CountryId], cancellationToken)
            ?? throw new ResourceNotFoundException("Drzava nije pronadjena.");
        var name = Required(request.Name, "Naziv grada");
        if (await dbContext.Cities.AnyAsync(x => x.CountryId == request.CountryId && x.Name == name, cancellationToken))
            throw new BusinessRuleException("Grad sa istim nazivom vec postoji u odabranoj drzavi.");
        var entity = new City { Name = name, PostalCode = Optional(request.PostalCode), CountryId = country.Id };
        dbContext.Cities.Add(entity);
        await SaveChangesAsync(cancellationToken);
        return new CityDto(entity.Id, entity.Name, entity.PostalCode, country.Id, country.Name);
    }

    public async Task<CityDto?> UpdateCityAsync(int id, SaveCityRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.Cities.FindAsync([id], cancellationToken);
        if (entity is null) return null;
        var country = await dbContext.Countries.FindAsync([request.CountryId], cancellationToken)
            ?? throw new ResourceNotFoundException("Drzava nije pronadjena.");
        var name = Required(request.Name, "Naziv grada");
        if (await dbContext.Cities.AnyAsync(x => x.Id != id && x.CountryId == request.CountryId && x.Name == name, cancellationToken))
            throw new BusinessRuleException("Grad sa istim nazivom vec postoji u odabranoj drzavi.");
        entity.Name = name;
        entity.PostalCode = Optional(request.PostalCode);
        entity.CountryId = request.CountryId;
        entity.UpdatedAtUtc = DateTime.UtcNow;
        await SaveChangesAsync(cancellationToken);
        return new CityDto(entity.Id, entity.Name, entity.PostalCode, country.Id, country.Name);
    }

    public async Task<bool> DeleteCityAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.Cities.FindAsync([id], cancellationToken);
        if (entity is null) return false;
        if (await dbContext.Cabins.AnyAsync(x => x.CityId == id, cancellationToken))
            throw new BusinessRuleException("Grad nije moguce obrisati jer ga koriste vikendice.");
        dbContext.Cities.Remove(entity);
        await SaveChangesAsync(cancellationToken);
        return true;
    }

    public Task<CabinTypeDto> CreateCabinTypeAsync(SaveCabinTypeRequest request, CancellationToken cancellationToken = default) =>
        CreateNamedAsync<CabinType, CabinTypeDto>(request.Name, request.Description,
            (name, description) => new CabinType { Name = name, Description = description },
            x => new CabinTypeDto(x.Id, x.Name, x.Description), cancellationToken);

    public Task<CabinTypeDto?> UpdateCabinTypeAsync(int id, SaveCabinTypeRequest request, CancellationToken cancellationToken = default) =>
        UpdateNamedAsync<CabinType, CabinTypeDto>(id, request.Name, request.Description,
            (entity, name, description) => { entity.Name = name; entity.Description = description; },
            x => new CabinTypeDto(x.Id, x.Name, x.Description), cancellationToken);

    public async Task<bool> DeleteCabinTypeAsync(int id, CancellationToken cancellationToken = default)
    {
        if (await dbContext.Cabins.AnyAsync(x => x.CabinTypeId == id, cancellationToken))
            throw new BusinessRuleException("Tip nije moguce obrisati jer ga koriste vikendice.");
        return await DeleteEntityAsync<CabinType>(id, cancellationToken);
    }

    public Task<AmenityDto> CreateAmenityAsync(SaveAmenityRequest request, CancellationToken cancellationToken = default) =>
        CreateNamedAsync<Amenity, AmenityDto>(request.Name, request.Icon,
            (name, icon) => new Amenity { Name = name, Icon = icon },
            x => new AmenityDto(x.Id, x.Name, x.Icon), cancellationToken);

    public Task<AmenityDto?> UpdateAmenityAsync(int id, SaveAmenityRequest request, CancellationToken cancellationToken = default) =>
        UpdateNamedAsync<Amenity, AmenityDto>(id, request.Name, request.Icon,
            (entity, name, icon) => { entity.Name = name; entity.Icon = icon; },
            x => new AmenityDto(x.Id, x.Name, x.Icon), cancellationToken);

    public async Task<bool> DeleteAmenityAsync(int id, CancellationToken cancellationToken = default)
    {
        if (await dbContext.Set<CabinAmenity>().AnyAsync(x => x.AmenityId == id, cancellationToken))
            throw new BusinessRuleException("Pogodnost nije moguce obrisati jer je dodijeljena vikendicama.");
        return await DeleteEntityAsync<Amenity>(id, cancellationToken);
    }

    public Task<RoleDto> CreateRoleAsync(SaveRoleRequest request, CancellationToken cancellationToken = default) =>
        CreateNamedAsync<Role, RoleDto>(request.Name, request.Description,
            (name, description) => new Role { Name = name, Description = description },
            x => new RoleDto(x.Id, x.Name, x.Description), cancellationToken);

    public Task<RoleDto?> UpdateRoleAsync(int id, SaveRoleRequest request, CancellationToken cancellationToken = default) =>
        UpdateNamedAsync<Role, RoleDto>(id, request.Name, request.Description,
            (entity, name, description) => { entity.Name = name; entity.Description = description; },
            x => new RoleDto(x.Id, x.Name, x.Description), cancellationToken);

    public async Task<bool> DeleteRoleAsync(int id, CancellationToken cancellationToken = default)
    {
        if (await dbContext.Set<UserRole>().AnyAsync(x => x.RoleId == id, cancellationToken))
            throw new BusinessRuleException("Ulogu nije moguce obrisati jer je dodijeljena korisnicima.");
        return await DeleteEntityAsync<Role>(id, cancellationToken);
    }

    private async Task<TDto> CreateNamedAsync<TEntity, TDto>(string value, string? optional,
        Func<string, string?, TEntity> create, Func<TEntity, TDto> map, CancellationToken cancellationToken)
        where TEntity : Entity
    {
        var name = Required(value, "Naziv");
        if (await dbContext.Set<TEntity>().AnyAsync(x => EF.Property<string>(x, "Name") == name, cancellationToken))
            throw new BusinessRuleException("Zapis sa istim nazivom vec postoji.");
        var entity = create(name, Optional(optional));
        dbContext.Add(entity);
        await SaveChangesAsync(cancellationToken);
        return map(entity);
    }

    private async Task<TDto?> UpdateNamedAsync<TEntity, TDto>(int id, string value, string? optional,
        Action<TEntity, string, string?> update, Func<TEntity, TDto> map, CancellationToken cancellationToken)
        where TEntity : Entity
    {
        var entity = await dbContext.Set<TEntity>().FindAsync([id], cancellationToken);
        if (entity is null) return default;
        var name = Required(value, "Naziv");
        if (await dbContext.Set<TEntity>().AnyAsync(x => x.Id != id && EF.Property<string>(x, "Name") == name, cancellationToken))
            throw new BusinessRuleException("Zapis sa istim nazivom vec postoji.");
        update(entity, name, Optional(optional));
        entity.UpdatedAtUtc = DateTime.UtcNow;
        await SaveChangesAsync(cancellationToken);
        return map(entity);
    }

    private async Task<bool> DeleteEntityAsync<TEntity>(int id, CancellationToken cancellationToken) where TEntity : Entity
    {
        var entity = await dbContext.Set<TEntity>().FindAsync([id], cancellationToken);
        if (entity is null) return false;
        dbContext.Remove(entity);
        await SaveChangesAsync(cancellationToken);
        return true;
    }

    private static string Required(string value, string field) =>
        string.IsNullOrWhiteSpace(value) ? throw new RequestValidationException($"{field} je obavezan.") : value.Trim();

    private static string? Optional(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private async Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        await dbContext.SaveChangesAsync(cancellationToken);
        cacheState.Bump();
    }
}
