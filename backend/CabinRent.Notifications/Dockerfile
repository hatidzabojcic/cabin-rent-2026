FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY CabinRent.sln Directory.Build.props ./
COPY backend/CabinRent.Notifications/CabinRent.Notifications.csproj backend/CabinRent.Notifications/
COPY backend/CabinRent.Infrastructure/CabinRent.Infrastructure.csproj backend/CabinRent.Infrastructure/
COPY backend/CabinRent.Model/CabinRent.Model.csproj backend/CabinRent.Model/
COPY backend/CabinRent.Services/CabinRent.Services.csproj backend/CabinRent.Services/
RUN dotnet restore backend/CabinRent.Notifications/CabinRent.Notifications.csproj
COPY . .
RUN dotnet publish backend/CabinRent.Notifications/CabinRent.Notifications.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/runtime:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "CabinRent.Notifications.dll"]
