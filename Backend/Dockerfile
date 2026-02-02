# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["PcmBackend.csproj", "."]
RUN dotnet restore "./PcmBackend.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "PcmBackend.csproj" -c $BUILD_CONFIGURATION -o /app/build
# Stage 2: Publish
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "PcmBackend.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Stage 3: Final
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "PcmBackend.dll"]