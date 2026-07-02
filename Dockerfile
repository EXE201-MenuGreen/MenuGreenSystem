# Sử dụng base image .NET 9.0 ASP.NET (dùng cho chạy ứng dụng)
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
# Render gán PORT lúc runtime (thường 10000); không set ASPNETCORE_URLS trong image.
EXPOSE 10000
EXPOSE 5000

# Install curl for healthchecks and dotnet SDK + ef tools for migrations
RUN apt-get update && apt-get install -y --no-install-recommends curl unzip && rm -rf /var/lib/apt/lists/* \
    && curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 9.0 --install-dir /opt/dotnet \
    && /opt/dotnet/dotnet tool install --global dotnet-ef || true

ENV DOTNET_ROOT=/opt/dotnet
ENV PATH="${PATH}:/root/.dotnet/tools"

# Sử dụng base image .NET 9.0 SDK (dùng cho build)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Cài đặt EF Core tools (cần cho migration lúc deploy)
RUN dotnet tool install --global dotnet-ef || true
ENV PATH="${PATH}:/root/.dotnet/tools"

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
WORKDIR /app
COPY --from=publish /app/publish .

# Copy EF tools từ build stage (bao gồm dotnet-ef)
COPY --from=build /root/.dotnet/tools /root/.dotnet/tools
COPY --from=build /opt/dotnet /opt/dotnet
ENV PATH="/opt/dotnet:/root/.dotnet/tools:${PATH}"
ENV DOTNET_ROOT=/opt/dotnet

ENTRYPOINT ["dotnet", "MenuGreen.API.dll"]
