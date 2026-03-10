@echo off
REM Script to remove obsolete Microsoft.Extensions.Configuration.AzureKeyVault package

echo Removing obsolete Microsoft.Extensions.Configuration.AzureKeyVault from projects...
echo.

cd /d "C:\Users\ALLEGRANathan\source\repos\eShopOnContainers\src\Services\Catalog\Catalog.API"
echo Catalog.API...
dotnet remove package Microsoft.Extensions.Configuration.AzureKeyVault
if %errorlevel% neq 0 echo Failed to remove from Catalog.API

cd /d "C:\Users\ALLEGRANathan\source\repos\eShopOnContainers\src\Services\Identity\Identity.API"
echo Identity.API...
dotnet remove package Microsoft.Extensions.Configuration.AzureKeyVault
if %errorlevel% neq 0 echo Failed to remove from Identity.API

cd /d "C:\Users\ALLEGRANathan\source\repos\eShopOnContainers\src\Services\Ordering\Ordering.API"
echo Ordering.API...
dotnet remove package Microsoft.Extensions.Configuration.AzureKeyVault
if %errorlevel% neq 0 echo Failed to remove from Ordering.API (might not exist)

cd /d "C:\Users\ALLEGRANathan\source\repos\eShopOnContainers"
echo.
echo Done! Now rebuilding to verify...
dotnet build src/eShopOnContainers-ServicesAndWebApps.sln --configuration Release

echo.
echo Checking for vulnerabilities...
dotnet list src/Services/Basket/Basket.API/Basket.API.csproj package --vulnerable --include-transitive
