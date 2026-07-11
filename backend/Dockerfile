# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj files and restore dependencies
COPY ["MenuGreen.API/MenuGreen.API.csproj", "MenuGreen.API/"]
COPY ["MenuGreen.BusinessLogicLayer/MenuGreen.BusinessLogicLayer.csproj", "MenuGreen.BusinessLogicLayer/"]
COPY ["MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj", "MenuGreen.DataAccessLayer/"]
RUN dotnet restore "MenuGreen.API/MenuGreen.API.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/MenuGreen.API"
RUN dotnet build "MenuGreen.API.csproj" -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish "MenuGreen.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 3: Final runtime image
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy published app
COPY --from=publish /app/publish .

# Expose port (Render injects PORT env)
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5000/health/live || exit 1

# Run the app
ENTRYPOINT ["dotnet", "MenuGreen.API.dll"]
