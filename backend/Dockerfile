# =============================================================================
# WARNING: This file is intentionally kept in sync with the root Dockerfile
# (../Dockerfile). The CI/CD pipeline (.github/workflows/backend-ci.yml) builds
# with `context: .` and uses the ROOT Dockerfile (../Dockerfile). Only this copy
# is here as a fallback for local `docker build -f backend/Dockerfile .`
# workflows. If you change build behaviour, edit both files or change the
# pipeline to point here.
# =============================================================================

# Sử dụng base image .NET 9.0 ASP.NET (dùng cho chạy ứng dụng)
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
# Render gán PORT lúc runtime (thường 10000); không set ASPNETCORE_URLS trong image.
EXPOSE 10000
EXPOSE 5000

# Sử dụng base image .NET 9.0 SDK (dùng cho build)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
# Capture the commit SHA that built this image so the running app can log it.
ARG GIT_SHA=unknown
WORKDIR /src

# Copy file .csproj và restore các packages
COPY ["MenuGreen.API/MenuGreen.API.csproj", "MenuGreen.API/"]
COPY ["MenuGreen.BusinessLogicLayer/MenuGreen.BusinessLogicLayer.csproj", "MenuGreen.BusinessLogicLayer/"]
COPY ["MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj", "MenuGreen.DataAccessLayer/"]
RUN dotnet restore "MenuGreen.API/MenuGreen.API.csproj"

# Copy toàn bộ mã nguồn
COPY . .
WORKDIR "/src/MenuGreen.API"

# Build ứng dụng
RUN dotnet build "MenuGreen.API.csproj" -c Release -o /app/build

# Publish ứng dụng (tối ưu hóa)
FROM build AS publish
RUN dotnet publish "MenuGreen.API.csproj" -c Release -o /app/publish

# Cấu hình container cuối cùng (Chỉ chứa code đã publish để giảm dung lượng)
FROM base AS final

ARG GIT_SHA=unknown
ENV GIT_SHA=${GIT_SHA}

# Install curl so HEALTHCHECK and docker-compose healthcheck can run.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=publish /app/publish .

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -fsS http://localhost:5000/health/live || exit 1

ENTRYPOINT ["dotnet", "MenuGreen.API.dll"]
