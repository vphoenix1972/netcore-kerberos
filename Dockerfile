FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
RUN apt-get update && apt-get install -y \
    krb5-user
ENV KRB5_KTNAME=/mnt/volume/krb5.keytab
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
COPY ["NetCoreKerberos/NetCoreKerberos.csproj", "NetCoreKerberos/"]
RUN dotnet restore "NetCoreKerberos/NetCoreKerberos.csproj"
COPY . .
WORKDIR "/src/NetCoreKerberos"
RUN dotnet build "NetCoreKerberos.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "NetCoreKerberos.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "NetCoreKerberos.dll"]