FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["EtlDotnet.csproj", "./"]
RUN dotnet restore "EtlDotnet.csproj"
COPY . .
RUN dotnet publish "EtlDotnet.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .

# Create directories for logs and state
RUN mkdir -p /app/logs/customers \
    && mkdir -p /app/logs/orders \
    && mkdir -p /app/state/orders \
    && chown -R 1000:1000 /app/logs \
    && chown -R 1000:1000 /app/state

USER 1000
ENTRYPOINT ["dotnet", "EtlDotnet.dll"]
