# Sử dụng base image .NET 9.0 ASP.NET (dùng cho chạy ứng dụng)
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5000

# Sử dụng base image .NET 9.0 SDK (dùng cho build)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
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
RUN dotnet publish "MenuGreen.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Cấu hình container cuối cùng (Chỉ chứa code đã publish để giảm dung lượng)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MenuGreen.API.dll"]
