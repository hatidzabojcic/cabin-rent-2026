FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY CabinRent.sln Directory.Build.props ./
COPY backend/CabinRent.API/CabinRent.API.csproj backend/CabinRent.API/
COPY backend/CabinRent.Model/CabinRent.Model.csproj backend/CabinRent.Model/
COPY backend/CabinRent.Services/CabinRent.Services.csproj backend/CabinRent.Services/
COPY backend/CabinRent.Infrastructure/CabinRent.Infrastructure.csproj backend/CabinRent.Infrastructure/
COPY backend/CabinRent.Notifications/CabinRent.Notifications.csproj backend/CabinRent.Notifications/
COPY tests/CabinRent.UnitTests/CabinRent.UnitTests.csproj tests/CabinRent.UnitTests/
RUN dotnet restore CabinRent.sln
COPY . .
RUN dotnet publish backend/CabinRent.API/CabinRent.API.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "CabinRent.API.dll"]
