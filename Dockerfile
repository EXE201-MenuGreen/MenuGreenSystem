# Sử dụng base image .NET 9.0 ASP.NET (dùng cho chạy ứng dụng)
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
# Render gán PORT lúc runtime (thường 10000); không set ASPNETCORE_URLS trong image.
EXPOSE 10000
EXPOSE 5000

# Sử dụng base image .NET 9.0 SDK (dùng cho build)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
# Capture the commit SHA that built this image so the running app can log it.
# CI passes this via --build-arg GIT_SHA=<sha>. Default keeps "manual" for
# local `docker build` invocations.
ARG GIT_SHA=unknown
WORKDIR /src

# Copy file .csproj và restore các packages
COPY ["backend/MenuGreen.API/MenuGreen.API.csproj", "backend/MenuGreen.API/"]
COPY ["backend/MenuGreen.BusinessLogicLayer/MenuGreen.BusinessLogicLayer.csproj", "backend/MenuGreen.BusinessLogicLayer/"]
COPY ["backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj", "backend/MenuGreen.DataAccessLayer/"]
RUN dotnet restore "backend/MenuGreen.API/MenuGreen.API.csproj"

# Copy toàn bộ mã nguồn
COPY . .
WORKDIR "/src/backend/MenuGreen.API"

# Build ứng dụng
RUN dotnet build "MenuGreen.API.csproj" -c Release -o /app/build

# Publish ứng dụng (tối ưu hóa)
FROM build AS publish
RUN dotnet publish "MenuGreen.API.csproj" -c Release -o /app/publish

# Cấu hình container cuối cùng (Chỉ chứa code đã publish để giảm dung lượng)
FROM base AS final

# Propagate the commit SHA into the runtime image so /health/ready and
# the app startup log can both report which commit is actually serving traffic.
ARG GIT_SHA=unknown
ENV GIT_SHA=${GIT_SHA}

# Install curl for both Docker HEALTHCHECK and the in-container healthcheck
# used by docker-compose.prod.yml (which calls `curl http://localhost:5000/health/live`).
# The base `aspnet:9.0` image is debian-slim and does NOT include curl.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=publish /app/publish .

# Container-level health check. Mirrors what docker-compose.prod.yml invokes
# in its own healthcheck block, but this one runs even outside compose.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -fsS http://localhost:5000/health/live || exit 1

ENTRYPOINT ["dotnet", "MenuGreen.API.dll"]
